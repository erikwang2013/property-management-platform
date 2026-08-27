<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\process\Monitor;
use PHPUnit\Framework\TestCase;

/**
 * 文件监控进程测试：暂停/恢复状态通过 runtime/monitor.lock 文件表达
 * 仅验证状态机语义，不启动真实监控循环
 */
class MonitorProcessTest extends TestCase
{
    protected function tearDown(): void
    {
        Monitor::resume();
    }

    public function test_pause_resume_toggles_lockfile_state(): void
    {
        Monitor::resume();
        $this->assertFalse(Monitor::isPaused(), '初始应为未暂停');

        Monitor::pause();
        $this->assertTrue(Monitor::isPaused(), 'pause 后应处于暂停态');

        Monitor::resume();
        $this->assertFalse(Monitor::isPaused(), 'resume 后应恢复未暂停');
    }

    public function test_pause_is_idempotent(): void
    {
        Monitor::pause();
        Monitor::pause();
        $this->assertTrue(Monitor::isPaused());
    }

    public function test_lock_file_located_in_runtime(): void
    {
        Monitor::pause();
        $this->assertFileExists(runtime_path('monitor.lock'));
        $this->assertStringContainsString('runtime', runtime_path('monitor.lock'));
    }
}
