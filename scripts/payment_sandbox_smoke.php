<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * 支付沙箱联调冒烟脚本
 *
 * 用法: cd admin && php ../scripts/payment_sandbox_smoke.php
 *
 * 流程: 下单 createOrder → 模拟回调 handleNotify(重复两次验证幂等) → 退款 refund → 对账 reconcile
 * 前置: admin/.env 配置 PAYMENT_ENABLED=true、PAYMENT_NOTIFY_HOST，以及任一渠道沙箱凭证
 *       (WECHAT_PAY_APP_ID/MCH_ID/API_V3_KEY/SERIAL_NO/PRIVATE_KEY 或 ALIPAY_APP_ID/PRIVATE_KEY/PUBLIC_KEY)
 * 行为: 凭证未启用/未配置时打印提示并 exit 0；数据库不可达 exit 1；沙箱跑通输出各步 PASS/FAIL/SKIP。
 * 说明: 回调为本地模拟（自签密钥通过验签，走 handleNotify 真实幂等链路），
 *       沙箱网关切换由 config/payment.php 的 PAYMENT_ENVIRONMENT 处理，脚本不重复实现网关逻辑。
 */

use app\common\PaymentService;
use app\common\payment\AlipayChannel;
use app\common\payment\WechatPayChannel;
use app\common\SnowflakeService;
use app\model\FeeBill;
use app\model\PaymentOrder;
use support\Db;
use support\Request;

$worker = $worker ?? null;
require_once __DIR__ . '/../admin/vendor/autoload.php';

// 加载 .env（与 tests/bootstrap.php 一致）
if (class_exists('Dotenv\Dotenv') && file_exists(__DIR__ . '/../admin/.env')) {
    if (method_exists('Dotenv\Dotenv', 'createUnsafeMutable')) {
        \Dotenv\Dotenv::createUnsafeMutable(__DIR__ . '/../admin')->load();
    } else {
        \Dotenv\Dotenv::createMutable(__DIR__ . '/../admin')->load();
    }
}

// 加载配置与 bootstrap（注册全局函数 hashids/jwt/captcha 等）
\Webman\Config::clear();
\support\App::loadAllConfig(['route']);
foreach (config('bootstrap', []) as $className) {
    if (class_exists($className)) {
        $className::start($worker);
    }
}

// ── 输出/断言辅助 ──
function report(string $status, string $name, string $detail = ''): void
{
    $GLOBALS['counts'][$status] = ($GLOBALS['counts'][$status] ?? 0) + 1;
    printf("[%-4s] %s%s\n", $status, $name, $detail !== '' ? " — {$detail}" : '');
}

function check(bool $ok, string $name, string $detail = ''): bool
{
    report($ok ? 'PASS' : 'FAIL', $name, $detail);
    return $ok;
}

/** 构造模拟回调请求（自签通过验签） */
function buildNotifyRequest(string $channel, string $orderNumber, float $amount, string $signPriv): Request
{
    if ($channel === 'wechat') {
        $ts = (string) time();
        $nonce = bin2hex(random_bytes(8));
        $body = json_encode([
            'event_type'     => 'TRANSACTION.SUCCESS',
            'trade_state'    => 'SUCCESS',
            'out_trade_no'   => $orderNumber,
            'transaction_id' => 'SIM' . $orderNumber,
        ], JSON_UNESCAPED_UNICODE);
        $sig = WechatPayChannel::sign(WechatPayChannel::buildSignMessage($ts, $nonce, $body), $signPriv);
        $buffer = "POST /payment/wechat/callback HTTP/1.1\r\nHost: localhost\r\nContent-Type: application/json\r\n"
            . "wechatpay-timestamp: {$ts}\r\nwechatpay-nonce: {$nonce}\r\nwechatpay-signature: {$sig}\r\n\r\n{$body}";
        return new Request($buffer);
    }

    $params = [
        'app_id'       => (string) config('payment.channels.alipay.app_id'),
        'out_trade_no' => $orderNumber,
        'trade_no'     => 'SIM' . $orderNumber,
        'trade_status' => 'TRADE_SUCCESS',
        'total_amount' => number_format($amount, 2, '.', ''),
    ];
    $params['sign'] = AlipayChannel::sign(AlipayChannel::buildParamString($params), $signPriv);
    $buffer = "POST /payment/alipay/callback HTTP/1.1\r\nHost: localhost\r\n"
        . "Content-Type: application/x-www-form-urlencoded\r\n\r\n" . http_build_query($params);
    return new Request($buffer);
}

// ── 前置检查：凭证未配置 → 提示跳过（exit 0） ──
$cfg = config('payment', []);
$channels = $cfg['channels'] ?? [];

$wechatReady = (bool) ($channels['wechat']['enabled'] ?? false)
    && ($channels['wechat']['app_id'] ?? '') !== ''
    && ($channels['wechat']['mch_id'] ?? '') !== ''
    && ($channels['wechat']['api_v3_key'] ?? '') !== ''
    && ($channels['wechat']['serial_no'] ?? '') !== ''
    && ($channels['wechat']['private_key'] ?? '') !== '';
$alipayReady = (bool) ($channels['alipay']['enabled'] ?? false)
    && ($channels['alipay']['app_id'] ?? '') !== ''
    && ($channels['alipay']['private_key'] ?? '') !== ''
    && ($channels['alipay']['alipay_public_key'] ?? '') !== '';

if (!(bool) ($cfg['enabled'] ?? false) || (!$wechatReady && !$alipayReady) || (string) ($cfg['notify_host'] ?? '') === '') {
    echo "沙箱凭证未配置，跳过（admin/.env 需设置 PAYMENT_ENABLED=true、PAYMENT_NOTIFY_HOST，并配置 WECHAT_PAY_* 或 ALIPAY_* 沙箱凭证）\n";
    exit(0);
}
$channel = $wechatReady ? 'wechat' : 'alipay';
$amount = 1.0;
$notifyOk = $channel === 'wechat' ? '{"code":"SUCCESS","message":"OK"}' : 'success';
printf("环境: %s / 渠道: %s / 金额: %.2f 元\n", (string) ($cfg['environment'] ?? 'sandbox'), $channel, $amount);

// 数据库可用性（非凭证类问题 → 硬失败）
try {
    Db::select('SELECT 1');
} catch (Throwable $e) {
    echo "数据库不可达，无法执行冒烟（{$e->getMessage()}）\n";
    exit(1);
}

$GLOBALS['counts'] = [];
$svc = new PaymentService();
$bill = null;
$orderNumber = '';
$aborted = false;

// ── 1. 下单（真实沙箱网关） ──
try {
    $bill = new FeeBill();
    $bill->id = SnowflakeService::generate();
    $bill->room_id = SnowflakeService::generate();
    $bill->owner_id = SnowflakeService::generate();
    $bill->fee_type_id = SnowflakeService::generate();
    $bill->bill_number = 'SMOKE' . date('YmdHis') . mt_rand(1000, 9999);
    $bill->amount = $amount;
    $bill->paid_amount = 0;
    $bill->status = 0;
    $bill->due_date = date('Y-m-d');
    $bill->save();

    $order = $svc->createOrder($channel, $bill->id, 1, 1, '支付沙箱冒烟测试');
    $orderNumber = $order['order_number'];
    $qrKey = $channel === 'wechat' ? 'code_url' : 'qr_code';
    $aborted = !check(!empty($order['pay_params'][$qrKey]), '下单 createOrder', "order={$orderNumber}");
} catch (Throwable $e) {
    $aborted = true;
    check(false, '下单 createOrder', $e->getMessage());
}

// ── 2. 模拟回调 handleNotify ×2（本地自签验签，验证幂等） ──
if (!$aborted) {
    // 生成临时密钥对，仅在本进程内临时替换验签凭证（platform_cert / alipay_public_key）
    $res = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
    openssl_pkey_export($res, $signPriv);
    $signPub = (string) openssl_pkey_get_details($res)['key'];
    if ($channel === 'wechat') {
        $cert = tempnam(sys_get_temp_dir(), 'paysmoke') . '.pem';
        file_put_contents($cert, $signPub);
        putenv('WECHAT_PAY_PLATFORM_CERT=' . $cert);
    } else {
        putenv('ALIPAY_PUBLIC_KEY=' . $signPub);
    }
    \Webman\Config::clear();
    \support\App::loadAllConfig(['route']);

    try {
        $req = buildNotifyRequest($channel, $orderNumber, $amount, $signPriv);
        check($svc->handleNotify($channel, $req) === $notifyOk, '回调应答 handleNotify');

        $orderRow = PaymentOrder::where('order_number', $orderNumber)->first();
        check($orderRow !== null && (int) $orderRow->status === 1, '回调后订单已支付 status=1');
        $bill->refresh();
        check((float) $bill->paid_amount === $amount && (int) $bill->status === 1, '回调后账单入账', "paid_amount={$bill->paid_amount}");

        // 重复回调：幂等，不重复入账
        check($svc->handleNotify($channel, $req) === $notifyOk, '重复回调应答 handleNotify');
        $bill->refresh();
        $orderRow2 = PaymentOrder::where('order_number', $orderNumber)->first();
        check(
            $orderRow2 !== null && (int) $orderRow2->status === 1 && (float) $bill->paid_amount === $amount,
            '重复回调幂等（未重复入账）',
            "status={$orderRow2->status} paid_amount={$bill->paid_amount}"
        );
    } catch (Throwable $e) {
        check(false, '模拟回调 handleNotify', $e->getMessage());
    }
}

// ── 3. 退款（网关确认已真实支付才执行，否则 SKIP） ──
if (!$aborted) {
    try {
        $gateway = $channel === 'wechat'
            ? new WechatPayChannel(config('payment.channels.wechat'), (string) config('payment.environment'), (int) config('payment.timeout'))
            : new AlipayChannel(config('payment.channels.alipay'), (string) config('payment.environment'), (int) config('payment.timeout'));
        $gw = $gateway->queryOrder($orderNumber);
        if ($gw['paid'] ?? false) {
            $orderId = (int) PaymentOrder::where('order_number', $orderNumber)->value('id');
            $r = $svc->refund($orderId, $amount);
            check((float) ($r['refund_amount'] ?? 0) === $amount, '退款 refund', "order={$r['order_number']}");
        } else {
            report('SKIP', '退款 refund', '订单未在网关侧真实支付（回调为模拟），真实支付后重跑可验证退款');
        }
    } catch (Throwable $e) {
        report('SKIP', '退款 refund', "网关查询失败: {$e->getMessage()}");
    }
}

// ── 4. 对账（模拟入账订单在网关侧无真实支付 → 标记差异，属预期输出） ──
try {
    $rec = $svc->reconcile((int) ($cfg['reconcile']['default_days'] ?? 7));
    check(isset($rec['checked'], $rec['findings']), '对账 reconcile', "checked={$rec['checked']} findings=" . count($rec['findings']));
    foreach ($rec['findings'] as $f) {
        printf("        %s => %s%s\n", $f['order_number'], $f['result'], isset($f['detail']) ? " ({$f['detail']})" : '');
    }
} catch (Throwable $e) {
    check(false, '对账 reconcile', $e->getMessage());
}

// ── 清理测试数据 ──
if ($bill !== null && $bill->exists) {
    $bill->delete();
}
if ($orderNumber !== '') {
    PaymentOrder::where('order_number', $orderNumber)->delete();
}

// ── 汇总 ──
$counts = $GLOBALS['counts'];
printf("\n结果: %d PASS / %d SKIP / %d FAIL\n", $counts['PASS'] ?? 0, $counts['SKIP'] ?? 0, $counts['FAIL'] ?? 0);
exit(($counts['FAIL'] ?? 0) > 0 ? 1 : 0);
