<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\payment\WechatPayChannel;
use PHPUnit\Framework\TestCase;
use RuntimeException;

/**
 * 微信支付 v3 回调解密（AEAD_AES_256_GCM，纯静态函数，不连网/不连库）
 *
 * 回调交易字段只在 resource.ciphertext 里；解密失败必须抛异常，
 * 绝不能把未验证的明文当支付结果入账。
 */
class WechatNotifyTest extends TestCase
{
    private const KEY = '0123456789abcdef0123456789abcdef'; // 32 字节 API v3 密钥
    private const NONCE = 'abcdefghijkl';                    // 12 字节
    private const AAD = 'transaction';
    private const PLAINTEXT = '{"out_trade_no":"202610300001","transaction_id":"4200001","trade_state":"SUCCESS","amount":{"total":1050}}';

    /** 按微信规范加密：AES-256-GCM，密文末尾附加 16 字节 tag，再整体 base64 */
    private static function encrypt(string $plaintext, string $key, string $nonce, string $aad): string
    {
        $tag = '';
        $cipher = openssl_encrypt($plaintext, 'aes-256-gcm', $key, OPENSSL_RAW_DATA, $nonce, $tag, $aad);
        return base64_encode($cipher . $tag);
    }

    private static function resource(string $ciphertext): array
    {
        return [
            'algorithm'       => 'AEAD_AES_256_GCM',
            'nonce'           => self::NONCE,
            'associated_data' => self::AAD,
            'ciphertext'      => $ciphertext,
        ];
    }

    public function test_decrypts_resource_ciphertext(): void
    {
        $resource = self::resource(self::encrypt(self::PLAINTEXT, self::KEY, self::NONCE, self::AAD));
        $this->assertSame(self::PLAINTEXT, WechatPayChannel::decryptResource($resource, self::KEY));
    }

    public function test_tampered_tag_throws(): void
    {
        $cipher = base64_decode(self::encrypt(self::PLAINTEXT, self::KEY, self::NONCE, self::AAD), true);
        $cipher[strlen($cipher) - 1] = chr(ord($cipher[strlen($cipher) - 1]) ^ 0xFF);

        $this->expectException(RuntimeException::class);
        WechatPayChannel::decryptResource(self::resource(base64_encode($cipher)), self::KEY);
    }

    public function test_wrong_key_throws(): void
    {
        $resource = self::resource(self::encrypt(self::PLAINTEXT, self::KEY, self::NONCE, self::AAD));

        $this->expectException(RuntimeException::class);
        WechatPayChannel::decryptResource($resource, 'fedcba9876543210fedcba9876543210');
    }
}
