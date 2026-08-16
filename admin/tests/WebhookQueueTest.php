<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\WebhookService;
use app\queue\redis\WebhookDelivery;
use PHPUnit\Framework\TestCase;
use RuntimeException;

class WebhookQueueTest extends TestCase
{
    private array $calls = [];

    protected function setUp(): void
    {
        parent::setUp();
        $this->calls = [];
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
        WebhookService::$configResolver = null;
        WebhookService::$httpClient = null;
        WebhookService::$queueSender = null;
        parent::tearDown();
    }

    public function test_consume_delivers_signed_payload(): void
    {
        (new WebhookDelivery())->consume(['event' => 'fee_paid', 'data' => ['bill_id' => 7]]);

        $this->assertCount(1, $this->calls);
        [$url, $payload, $signature] = $this->calls[0];
        $this->assertSame('https://example.com/hook', $url);
        $decoded = json_decode($payload, true);
        $this->assertSame('fee_paid', $decoded['event']);
        $this->assertSame(['bill_id' => 7], $decoded['data']);
        $this->assertTrue(WebhookService::verify($payload, $signature, 'test-secret'));
    }

    public function test_consume_failure_throws_for_queue_retry(): void
    {
        WebhookService::$httpClient = fn (): int => 500;
        $this->expectException(RuntimeException::class);
        (new WebhookDelivery())->consume(['event' => 'fee_paid', 'data' => []]);
    }

    public function test_consume_empty_event_is_noop(): void
    {
        (new WebhookDelivery())->consume([]);
        $this->assertCount(0, $this->calls);
    }
}
