<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\EncryptionService;
use PHPUnit\Framework\TestCase;

class EncryptionServiceTest extends TestCase
{
    public function test_mask_phone_11_digits(): void
    {
        $this->assertSame('138****8000', EncryptionService::maskPhone('13800138000'));
    }

    public function test_mask_phone_7_digits_boundary(): void
    {
        $this->assertSame('123****4567', EncryptionService::maskPhone('1234567'));
    }

    public function test_mask_phone_short_returns_original(): void
    {
        $this->assertSame('12345', EncryptionService::maskPhone('12345'));
        $this->assertSame('', EncryptionService::maskPhone(''));
    }

    public function test_mask_email_normal(): void
    {
        $this->assertSame('a***@example.com', EncryptionService::maskEmail('abc@example.com'));
    }

    public function test_mask_email_short_name(): void
    {
        $this->assertSame('a**@example.com', EncryptionService::maskEmail('ab@example.com'));
    }

    public function test_mask_email_invalid_returns_original(): void
    {
        $this->assertSame('no-at-sign', EncryptionService::maskEmail('no-at-sign'));
    }

    public function test_encrypt_decrypt_roundtrip(): void
    {
        $plain = '13800138000';
        $encrypted = EncryptionService::encrypt($plain);
        $this->assertNotSame($plain, $encrypted, '加密结果不应等于明文');
        $this->assertNotEmpty($encrypted);
        $this->assertSame($plain, EncryptionService::decrypt($encrypted), '解密应还原明文');
    }

    public function test_encrypt_produces_different_ciphertext(): void
    {
        $this->assertNotSame(
            EncryptionService::encrypt('same-value'),
            EncryptionService::encrypt('same-value'),
            'AES 随机 IV：同明文两次加密结果应不同'
        );
    }

    public function test_empty_value_returns_empty(): void
    {
        $this->assertSame('', EncryptionService::encrypt(''));
        $this->assertSame('', EncryptionService::decrypt(''));
    }
}
