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
 * 微信支付 v3 渠道（Native 扫码）
 *
 * 沙箱网关: api.mch.weixin.qq.com/sandboxnew（仅沙箱商户可用）
 * 生产网关: api.mch.weixin.qq.com
 * 签名: RSA-SHA256（商户私钥签名，平台证书验签）
 */
class WechatPayChannel
{
    private const BASE = 'https://api.mch.weixin.qq.com';
    private const SANDBOX_PREFIX = '/sandboxnew';

    private Client $client;
    private array $cfg;

    public function __construct(array $cfg, string $environment, int $timeout)
    {
        $this->cfg = $cfg;
        $base = self::BASE . ($environment === 'sandbox' ? self::SANDBOX_PREFIX : '');
        $this->client = new Client(['base_uri' => $base, 'timeout' => $timeout]);
    }

    /** Native 下单，返回支付二维码内容 */
    public function prepay(string $orderNumber, string $subject, float $amount, string $notifyUrl): array
    {
        $body = [
            'appid'        => $this->cfg['app_id'],
            'mchid'        => $this->cfg['mch_id'],
            'description'  => $subject,
            'out_trade_no' => $orderNumber,
            'notify_url'   => $notifyUrl,
            'amount'       => ['total' => self::toCents($amount), 'currency' => 'CNY'],
        ];
        $resp = $this->request('POST', '/v3/pay/transactions/native', $body);
        if (empty($resp['code_url'])) {
            throw new RuntimeException('微信下单失败：缺少 code_url');
        }
        return ['code_url' => $resp['code_url']];
    }

    /** 退款，金额单位为元 */
    public function refund(string $orderNumber, string $refundNumber, float $amount, float $total): void
    {
        $body = [
            'out_trade_no'  => $orderNumber,
            'out_refund_no' => $refundNumber,
            'amount'        => [
                'refund' => self::toCents($amount),
                'total'  => self::toCents($total),
                'currency' => 'CNY',
            ],
        ];
        $this->request('POST', '/v3/refund/domestic/refunds', $body);
    }

    /** 查询订单支付状态，返回 ['paid' => bool, 'trade_no' => string, 'amount' => float] */
    public function queryOrder(string $orderNumber): array
    {
        $resp = $this->request('GET', '/v3/pay/transactions/out-trade-no/' . $orderNumber);
        return [
            'paid'     => ($resp['trade_state'] ?? '') === 'SUCCESS',
            'trade_no' => $resp['transaction_id'] ?? '',
            'amount'   => isset($resp['amount']['total']) ? (int) $resp['amount']['total'] / 100 : 0.0,
        ];
    }

    /** 回调验签：返回 ['order_number','trade_no','paid']，失败抛异常 */
    public function verifyNotify(string $body, array $headers): array
    {
        $timestamp = $headers['wechatpay-timestamp'] ?? '';
        $nonce     = $headers['wechatpay-nonce'] ?? '';
        $signature = $headers['wechatpay-signature'] ?? '';
        if ($timestamp === '' || $nonce === '' || $signature === '') {
            throw new RuntimeException('微信回调缺少签名头');
        }
        if (abs(time() - (int) $timestamp) > 300) {
            throw new RuntimeException('微信回调时间戳超时');
        }
        $pubKey = $this->publicKeyFromCert($this->cfg['platform_cert']);
        if (!self::verify(self::buildSignMessage($timestamp, $nonce, $body), $signature, $pubKey)) {
            throw new RuntimeException('微信回调验签失败');
        }

        $data = json_decode($body, true);
        if (!is_array($data)) {
            throw new RuntimeException('微信回调数据非法');
        }
        // 退款等非支付事件通知：直接应答成功，不处理
        if (isset($data['event_type']) && $data['event_type'] !== 'TRANSACTION.SUCCESS') {
            return ['order_number' => '', 'trade_no' => '', 'paid' => false];
        }
        $tradeState = $data['trade_state'] ?? '';
        return [
            'order_number' => $data['out_trade_no'] ?? '',
            'trade_no'     => $data['transaction_id'] ?? '',
            // 空/未知交易状态视为未支付：宁可等渠道重试，不可把未付款挂起回调当已支付入账
            'paid'         => $tradeState === 'SUCCESS',
        ];
    }

    private function request(string $method, string $path, array $body = []): array
    {
        $json = $body ? json_encode($body, JSON_UNESCAPED_UNICODE) : '';
        $headers = [
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
            'Authorization' => $this->authorization($method, $path, $json),
        ];
        try {
            $resp = $this->client->request($method, $path, ['headers' => $headers, 'body' => $json]);
            $data = json_decode((string) $resp->getBody(), true);
            if (!is_array($data)) {
                throw new RuntimeException('微信响应非法: ' . (string) $resp->getBody());
            }
            if (!empty($data['code'])) {
                throw new RuntimeException('微信API错误: ' . $data['code'] . ' ' . ($data['message'] ?? ''));
            }
            return $data;
        } catch (GuzzleException $e) {
            throw new RuntimeException('微信请求失败: ' . $e->getMessage());
        }
    }

    private function authorization(string $method, string $path, string $body): string
    {
        $timestamp = (string) time();
        $nonce = bin2hex(random_bytes(16));
        $message = "{$method}\n{$path}\n{$timestamp}\n{$nonce}\n{$body}\n";
        $signature = self::sign($message, $this->privateKey($this->cfg['private_key']));
        return sprintf(
            'WECHATPAY2-SHA256-RSA2048 mchid="%s",nonce_str="%s",signature="%s",timestamp="%s",serial_no="%s"',
            $this->cfg['mch_id'], $nonce, $signature, $timestamp, $this->cfg['serial_no']
        );
    }

    // ── 纯函数签名/验签（独立测试） ──

    /** v3 签名消息格式: timestamp\nnonce\nbody\n */
    public static function buildSignMessage(string $timestamp, string $nonce, string $body): string
    {
        return "{$timestamp}\n{$nonce}\n{$body}\n";
    }

    /** RSA-SHA256 签名，返回 base64 */
    public static function sign(string $message, string $privateKeyPem): string
    {
        $key = openssl_pkey_get_private($privateKeyPem);
        if ($key === false) {
            throw new RuntimeException('商户私钥无效');
        }
        openssl_sign($message, $signature, $key, OPENSSL_ALGO_SHA256);
        return base64_encode($signature);
    }

    /** RSA-SHA256 验签 */
    public static function verify(string $message, string $signatureB64, string $publicKeyPem): bool
    {
        $key = openssl_pkey_get_public($publicKeyPem);
        if ($key === false) {
            throw new RuntimeException('平台公钥无效');
        }
        $result = openssl_verify($message, base64_decode($signatureB64), $key, OPENSSL_ALGO_SHA256);
        return $result === 1;
    }

    /** 元 → 分（微信金额单位为分） */
    public static function toCents(float $amount): int
    {
        return (int) round($amount * 100);
    }

    private function privateKey(string $path): string
    {
        if (!is_file($path)) {
            throw new RuntimeException("微信商户私钥文件不存在: {$path}");
        }
        return (string) file_get_contents($path);
    }

    private function publicKeyFromCert(string $path): string
    {
        if (!is_file($path)) {
            throw new RuntimeException("微信平台证书文件不存在: {$path}");
        }
        $pem = (string) file_get_contents($path);
        $key = openssl_pkey_get_public($pem);
        if ($key === false) {
            throw new RuntimeException('微信平台证书解析失败');
        }
        return $pem;
    }
}
