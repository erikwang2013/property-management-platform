<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\WebhookService;
use PHPUnit\Framework\TestCase;

class WebhookServiceTest extends TestCase
{
    private array $calls = [];

    protected function setUp(): void
    {
        parent::setUp();
        $this->calls = [];
        WebhookService::$retryDelays = [0, 0];
        WebhookService::$configResolver = fn (): array => [
            'url'     => 'https://example.com/hook',
            'secret'  => 'test-secret',
            'events'  => ['fee_paid', 'repair_created'],
            'enabled' => true,
        ];
        WebhookService::$httpClient = function (string $url, string $payload, string $signature): int {
            $this->calls[] = [$url, $payload, $signature];
            return 200;
        };
    }

    protected function tearDown(): void
    {
        WebhookService::$retryDelays = [1, 2];
        WebhookService::$configResolver = null;
        WebhookService::$httpClient = null;
        parent::tearDown();
    }

    public function test_sign_verify_roundtrip_and_tamper_reject(): void
    {
        $signature = WebhookService::sign('{"event":"fee_paid"}', 'secret');
        $this->assertTrue(WebhookService::verify('{"event":"fee_paid"}', $signature, 'secret'));
        // 签名错误拒收：载荷被篡改 / 密钥不符 / 空签名
        $this->assertFalse(WebhookService::verify('{"event":"fee_paid"}x', $signature, 'secret'));
        $this->assertFalse(WebhookService::verify('{"event":"fee_paid"}', $signature, 'wrong-secret'));
        $this->assertFalse(WebhookService::verify('{"event":"fee_paid"}', '', 'secret'));
    }

    public function test_dispatch_payload_shape_and_signature(): void
    {
        $this->assertTrue(WebhookService::dispatch('fee_paid', ['bill_id' => 1, 'amount' => 100.5]));

        $this->assertCount(1, $this->calls);
        [$url, $payload, $signature] = $this->calls[0];
        $this->assertSame('https://example.com/hook', $url);
        $decoded = json_decode($payload, true);
        $this->assertSame('fee_paid', $decoded['event']);
        $this->assertArrayHasKey('occurred_at', $decoded);
        $this->assertSame(['bill_id' => 1, 'amount' => 100.5], $decoded['data']);
        // 载荷与签名一致：接收方可直接 verify 拒收
        $this->assertTrue(WebhookService::verify($payload, $signature, 'test-secret'));
    }

    public function test_retry_succeeds_after_failures(): void
    {
        $attempts = 0;
        WebhookService::$httpClient = function () use (&$attempts): int {
            $attempts++;
            return $attempts < 3 ? 500 : 200;
        };
        $this->assertTrue(WebhookService::dispatch('repair_created', ['id' => 9]));
        $this->assertSame(3, $attempts);
    }

    public function test_retry_exhausted_returns_false(): void
    {
        WebhookService::$httpClient = function (): int { // 网络失败
            $this->calls[] = [];
            return 0;
        };
        $this->assertFalse(WebhookService::dispatch('fee_paid', []));
        $this->assertCount(3, $this->calls); // 最多 3 次
    }

    public function test_unsubscribed_or_disabled_event_not_delivered(): void
    {
        WebhookService::dispatch('announcement_published', []); // 未订阅
        $this->assertCount(0, $this->calls);

        WebhookService::$configResolver = fn (): array => [
            'url' => 'https://example.com/hook', 'secret' => 's', 'events' => ['fee_paid'], 'enabled' => false,
        ];
        WebhookService::dispatch('fee_paid', []);
        $this->assertCount(0, $this->calls);
    }

    public function test_no_config_skips_silently(): void
    {
        WebhookService::$configResolver = fn (): ?array => null;
        $this->assertFalse(WebhookService::dispatch('fee_paid', []));
        $this->assertCount(0, $this->calls);
    }
}
