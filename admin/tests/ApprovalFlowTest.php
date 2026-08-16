<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\ApprovalController;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

class ApprovalFlowTest extends TestCase
{
    private const STEPS = [
        ['approver_id' => 11, 'approver_type' => 1],
        ['approver_id' => 22, 'approver_type' => 1],
    ];

    public function test_reject_ends_approval(): void
    {
        // 驳回：status=2，步骤不变，无下一步
        $this->assertSame([2, 1, false], ApprovalController::transition(2, 0, self::STEPS, 1));
    }

    public function test_approve_advances_to_next_step(): void
    {
        // 通过且存在下一步：status 保持 0（处理中），步骤 +1
        $this->assertSame([0, 2, true], ApprovalController::transition(1, 0, self::STEPS, 1));
    }

    public function test_approve_last_step_completes(): void
    {
        // 最后一步通过：status=1（已通过），无下一步
        $this->assertSame([1, 2, false], ApprovalController::transition(1, 0, self::STEPS, 2));
    }

    public function test_approve_single_step_completes(): void
    {
        $this->assertSame([1, 1, false], ApprovalController::transition(1, 0, [self::STEPS[0]], 1));
    }

    public function test_invalid_action_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);
        ApprovalController::transition(3, 0, self::STEPS, 1);
    }

    public function test_illegal_transition_on_rejected_approval(): void
    {
        // 已驳回(status=2)后不能再操作
        $this->expectException(InvalidArgumentException::class);
        ApprovalController::transition(1, 2, self::STEPS, 1);
    }

    public function test_illegal_transition_on_completed_approval(): void
    {
        // 已通过(status=1)后不能再操作
        $this->expectException(InvalidArgumentException::class);
        ApprovalController::transition(2, 1, self::STEPS, 2);
    }
}
