<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\ReportController;
use PHPUnit\Framework\TestCase;
use support\Request;

class ReportControllerTest extends TestCase
{
    private static function makeRequest(array $inputs = []): Request
    {
        return new class($inputs) extends Request {
            public function __construct(private array $inputs = [])
            {
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }
        };
    }

    private static function body($resp): array
    {
        return json_decode($resp->rawBody(), true);
    }

    public function testInvalidDateRangeRejected(): void
    {
        $controller = new ReportController();
        // 非法格式
        $resp = $controller->index(self::makeRequest(['start_date' => 'abc', 'end_date' => '2026-08-01']));
        $this->assertSame(422, self::body($resp)['code']);
        // 开始日期晚于结束日期
        $resp = $controller->index(self::makeRequest(['start_date' => '2026-09-01', 'end_date' => '2026-08-01']));
        $this->assertSame(422, self::body($resp)['code']);
    }

    public function testInvalidCommunityIdRejected(): void
    {
        $controller = new ReportController();
        $resp = $controller->index(self::makeRequest(['community_id' => '!!!not-a-hashid!!!']));
        $this->assertSame(404, self::body($resp)['code']);
    }
}
