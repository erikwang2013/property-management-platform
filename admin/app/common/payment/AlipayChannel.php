<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common\payment;

use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;
use RuntimeException;

/**
 * 支付宝渠道（当面付-预下单）
 *
 * 沙箱网关: openapi.alipaydev.com/gateway.do
 * 生产网关: openapi.alipay.com/gateway.do
 * 签名: RSA2（SHA256withRSA），参数按 key 排序后拼串签名
 */
class AlipayChannel
{
    private const GATEWAY_SANDBOX = 'https://openapi.alipaydev.com/gateway.do';
    private const GATEWAY_PRODUCTION = 'https://openapi.alipay.com/gateway.do';

    private Client $client;
    private array $cfg;
    private string $gateway;

    public function __construct(array $cfg, string $environment, int $timeout)
    {
        $this->cfg = $cfg;
        $this->gateway = $environment === 'sandbox' ? self::GATEWAY_SANDBOX : self::GATEWAY_PRODUCTION;
        $this->client = new Client(['timeout' => $timeout]);
    }

    /** 当面付预下单，返回收款二维码内容 */
    public function prepay(string $orderNumber, string $subject, float $amount): array
    {
        $bizContent = [
            'out_trade_no' => $orderNumber,
            'total_amount' => number_format($amount, 2, '.', ''),
            'subject'      => $subject,
            'timeout_express' => '15m',
        ];
        $resp = $this->call('alipay.trade.precreate', $bizContent);
        if (empty($resp['qr_code'])) {
            throw new RuntimeException('支付宝下单失败：缺少 qr_code');
        }
        return ['qr_code' => $resp['qr_code']];
    }

    /** 退款，金额单位为元 */
    public function refund(string $orderNumber, string $refundNumber, float $amount): void
    {
        $bizContent = [
            'out_trade_no'  => $orderNumber,
            'refund_amount' => number_format($amount, 2, '.', ''),
            'out_request_no' => $refundNumber,
        ];
        $resp = $this->call('alipay.trade.refund', $bizContent);
        if (($resp['code'] ?? '') !== '10000') {
            throw new RuntimeException('支付宝退款失败: ' . ($resp['sub_msg'] ?? $resp['msg'] ?? ''));
        }
    }

    /** 查询订单支付状态，返回 ['paid' => bool, 'trade_no' => string, 'amount' => float] */
    public function queryOrder(string $orderNumber): array
    {
        $resp = $this->call('alipay.trade.query', ['out_trade_no' => $orderNumber]);
        return [
            'paid'     => ($resp['trade_status'] ?? '') === 'TRADE_SUCCESS',
            'trade_no' => $resp['trade_no'] ?? '',
            'amount'   => (float) ($resp['total_amount'] ?? 0),
        ];
    }

    /** 回调验签：返回 ['order_number','trade_no','paid']，失败抛异常 */
    public function verifyNotify(array $params): array
    {
        if (empty($params['sign']) || empty($params['out_trade_no'])) {
            throw new RuntimeException('支付宝回调缺少签名或订单号');
        }
        if (($params['app_id'] ?? '') !== $this->cfg['app_id']) {
            throw new RuntimeException('支付宝回调 app_id 不匹配');
        }
        if (!self::verify(self::buildParamString($params), $params['sign'], $this->cfg['alipay_public_key'])) {
            throw new RuntimeException('支付宝回调验签失败');
        }
        $tradeStatus = $params['trade_status'] ?? '';
        return [
            'order_number' => $params['out_trade_no'],
            'trade_no'     => $params['trade_no'] ?? '',
            'paid'         => in_array($tradeStatus, ['TRADE_SUCCESS', 'TRADE_FINISHED'], true),
        ];
    }

    private function call(string $method, array $bizContent): array
    {
        $params = [
            'app_id'      => $this->cfg['app_id'],
            'method'      => $method,
            'format'      => 'JSON',
            'charset'     => 'utf-8',
            'sign_type'   => 'RSA2',
            'timestamp'   => date('Y-m-d H:i:s'),
            'version'     => '1.0',
            'biz_content' => json_encode($bizContent, JSON_UNESCAPED_UNICODE),
        ];
        $params['sign'] = self::sign(self::buildParamString($params), $this->cfg['private_key']);

        try {
            $resp = $this->client->post($this->gateway, ['form_params' => $params]);
            $data = json_decode((string) $resp->getBody(), true);
            if (!is_array($data)) {
                throw new RuntimeException('支付宝响应非法: ' . (string) $resp->getBody());
            }
            $responseKey = str_replace('.', '_', $method) . '_response';
            $result = $data[$responseKey] ?? null;
            if (!is_array($result) || ($result['code'] ?? '') !== '10000') {
                throw new RuntimeException('支付宝API错误: ' . ($result['sub_msg'] ?? $result['msg'] ?? 'unknown'));
            }
            return $result;
        } catch (GuzzleException $e) {
            throw new RuntimeException('支付宝请求失败: ' . $e->getMessage());
        }
    }

    // ── 纯函数签名/验签（独立测试） ──

    /** 参数按 key 升序拼接 k=v&...，剔除 sign/sign_type */
    public static function buildParamString(array $params): string
    {
        unset($params['sign'], $params['sign_type']);
        ksort($params, SORT_STRING);
        $pairs = [];
        foreach ($params as $k => $v) {
            if ($v === '' || $v === null) {
                continue;
            }
            $pairs[] = "{$k}={$v}";
        }
        return implode('&', $pairs);
    }

    /** RSA2（SHA256withRSA）签名，返回 base64 */
    public static function sign(string $message, string $privateKeyPem): string
    {
        $key = openssl_pkey_get_private($privateKeyPem);
        if ($key === false) {
            throw new RuntimeException('支付宝应用私钥无效');
        }
        openssl_sign($message, $signature, $key, OPENSSL_ALGO_SHA256);
        return base64_encode($signature);
    }

    /** RSA2 验签 */
    public static function verify(string $message, string $signatureB64, string $publicKeyPem): bool
    {
        $key = openssl_pkey_get_public($publicKeyPem);
        if ($key === false) {
            throw new RuntimeException('支付宝公钥无效');
        }
        $result = openssl_verify($message, base64_decode($signatureB64), $key, OPENSSL_ALGO_SHA256);
        return $result === 1;
    }
}
