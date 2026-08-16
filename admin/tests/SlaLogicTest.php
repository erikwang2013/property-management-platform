<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\SlaController;
use app\model\SlaRule;
use PHPUnit\Framework\TestCase;

class SlaLogicTest extends TestCase
{
    private static function rule(int $category, int $urgency, string $name = ''): SlaRule
    {
        return new SlaRule(['category' => $category, 'urgency' => $urgency, 'name' => $name]);
    }

    public function test_match_rule_prefers_exact_category_urgency(): void
    {
        // 同 category 多条规则时，精确匹配 urgency 优先于 category 兜底
        $rules = [
            self::rule(1, 2, 'urg2'),
            self::rule(1, 1, 'exact'),
            self::rule(2, 1, 'other'),
        ];
        $this->assertSame('exact', SlaController::matchRule($rules, 1, 1)->name);
    }

    public function test_match_rule_falls_back_to_category(): void
    {
        // 无 urgency 精确匹配时按 category 兜底
        $rules = [self::rule(1, 2, 'fallback'), self::rule(2, 1, 'other')];
        $this->assertSame('fallback', SlaController::matchRule($rules, 1, 1)->name);
    }

    public function test_match_rule_returns_null_when_no_match(): void
    {
        $this->assertNull(SlaController::matchRule([self::rule(3, 1)], 1, 1));
        $this->assertNull(SlaController::matchRule([], 1, 1));
    }

    public function test_add_minutes(): void
    {
        $this->assertSame('2026-08-16 11:30:00', SlaController::addMinutes('2026-08-16 10:00:00', 90));
        // 跨天
        $this->assertSame('2026-08-17 01:30:00', SlaController::addMinutes('2026-08-16 23:30:00', 120));
        $this->assertSame('2026-08-16 10:00:00', SlaController::addMinutes('2026-08-16 10:00:00', 0));
    }

    public function test_is_past(): void
    {
        $this->assertTrue(SlaController::isPast('2026-08-16 10:00:00', '2026-08-16 10:00:01'));
        $this->assertFalse(SlaController::isPast('2026-08-16 10:00:00', '2026-08-16 09:59:59'));
        // 恰好到截止时刻不算超时
        $this->assertFalse(SlaController::isPast('2026-08-16 10:00:00', '2026-08-16 10:00:00'));
    }

    public function test_should_escalate(): void
    {
        $createdAt = '2026-08-16 10:00:00';
        // 超过升级时限且未升级过
        $this->assertTrue(SlaController::shouldEscalate(60, $createdAt, '2026-08-16 11:01:00', false));
        // 未到升级时限
        $this->assertFalse(SlaController::shouldEscalate(60, $createdAt, '2026-08-16 10:59:00', false));
        // 未配置升级时限（0 表示不升级）
        $this->assertFalse(SlaController::shouldEscalate(0, $createdAt, '2026-08-16 12:00:00', false));
        // 已升级过不重复升级
        $this->assertFalse(SlaController::shouldEscalate(60, $createdAt, '2026-08-16 12:00:00', true));
    }
}
