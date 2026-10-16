<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use PHPUnit\Framework\TestCase;

/**
 * 安装向导字段奇偶性：step3 确认表单必须携带 step2 收集的全部字段。
 * 背景：确认页曾缺 admin_password_confirm（v1.7.0）与整组可选支付/ES 字段（2026-10），
 * 缺失即在确认环节被 processStep2 静默丢弃——「页面填了、装完没有」。
 */
class InstallWizardFieldParityTest extends TestCase
{
    /** @return string[] step 页面里所有 <input> 的 name 集合 */
    private static function inputNames(string $file): array
    {
        $html = file_get_contents(__DIR__ . '/../app/admin/view/install/' . $file);
        preg_match_all('/<input[^>]*\bname="([a-z_0-9]+)"/i', $html, $m);
        return array_values(array_unique($m[1]));
    }

    public function test_step3_form_carries_every_step2_field(): void
    {
        $missing = array_diff(self::inputNames('step2.html'), self::inputNames('step3.html'));
        $this->assertSame([], array_values($missing), 'step3 确认表单缺少字段(确认环节会被丢弃): ' . implode(', ', $missing));
    }

    public function test_step3_form_carries_optional_config_fields(): void
    {
        $step3 = self::inputNames('step3.html');
        $optional = [
            'payment_env', 'payment_notify_host',
            'wechat_app_id', 'wechat_mch_id', 'wechat_api_v3',
            'alipay_app_id', 'alipay_private',
            'es_host', 'es_username', 'es_password',
        ];
        foreach ($optional as $name) {
            $this->assertContains($name, $step3, "step3 缺少可选配置字段 {$name}");
        }
    }

    public function test_render_step3_forwards_optional_to_view(): void
    {
        $src = file_get_contents(__DIR__ . '/../app/admin/controller/InstallController.php');
        $this->assertStringContainsString("'optional'    => \$optional", $src,
            'renderStep3 必须把 $optional 传给视图，否则隐藏域无值可渲染');
    }
}
