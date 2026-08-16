<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\ExportController;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Db;
use support\Request;

class ExportControllerTest extends TestCase
{
    private static bool $dbAvailable = false;

    public static function setUpBeforeClass(): void
    {
        try {
            Db::select('select 1');
            self::$dbAvailable = true;
        } catch (\Throwable) {
            self::$dbAvailable = false;
        }
    }

    private static function invokePrivate(string $method, mixed ...$args): mixed
    {
        $ref = new ReflectionMethod(ExportController::class, $method);
        $ref->setAccessible(true);
        return $ref->invoke(new ExportController(), ...$args);
    }

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

    public function test_build_pdf_html_table_contains_rows(): void
    {
        $html = self::invokePrivate('buildPdfHtml', 'table', '测试导出', [
            'columns' => ['姓名', '手机号'],
            'rows'    => [['张三', '13800001111']],
        ]);
        $this->assertStringContainsString('<table>', $html);
        $this->assertStringContainsString('<th>姓名</th>', $html);
        $this->assertStringContainsString('<td>张三</td>', $html);
        $this->assertStringContainsString('13800001111', $html);
    }

    public function test_build_pdf_html_escapes_xss(): void
    {
        $html = self::invokePrivate('buildPdfHtml', 'table', '<script>alert(1)</script>', [
            'columns' => ['标题'],
            'rows'    => [['<img src=x onerror=alert(1)>']],
        ]);
        $this->assertStringNotContainsString('<script>alert(1)</script>', $html);
        $this->assertStringNotContainsString('<img src=x', $html);
        $this->assertStringContainsString('&lt;script&gt;', $html);
    }

    public function test_build_pdf_html_dashboard_cards(): void
    {
        $html = self::invokePrivate('buildPdfHtml', 'dashboard', '仪表盘', [
            'stats' => [
                ['label' => '业主数', 'value' => '128'],
                ['label' => '账单数', 'value' => '56'],
            ],
        ]);
        $this->assertStringContainsString('<div class="cards">', $html);
        $this->assertStringContainsString('业主数', $html);
        $this->assertStringContainsString('128', $html);
    }

    public function test_build_pdf_html_has_copyright_footer(): void
    {
        $html = self::invokePrivate('buildPdfHtml', 'table', 'x', []);
        $this->assertStringContainsString('erik.xyz', $html);
        $this->assertStringContainsString('本文件包含不可移除的版权信息', $html);
    }

    public function test_mask_phone(): void
    {
        $this->assertSame('138****5678', self::invokePrivate('maskPhone', '13812345678'));
        $this->assertSame('123', self::invokePrivate('maskPhone', '123')); // 不足 7 位不脱敏
        $this->assertSame('', self::invokePrivate('maskPhone', ''));
    }

    public function test_export_column_maps(): void
    {
        $columns = self::invokePrivate('getExportColumns', 'admin_user');
        $this->assertArrayHasKey('username', $columns);
        $this->assertArrayHasKey('phone', $columns);
        $this->assertArrayHasKey('created_at', $columns);
        $this->assertSame([], self::invokePrivate('getExportColumns', 'unknown_table'));
    }

    public function test_filterable_fields_whitelist(): void
    {
        $fields = self::invokePrivate('getFilterableFields', 'admin_user');
        $this->assertContains('username', $fields);
        $this->assertNotContains('id', $fields); // id 不允许作为过滤条件，防注入
        $this->assertSame([], self::invokePrivate('getFilterableFields', 'unknown_table'));
    }

    public function test_sensitive_fields(): void
    {
        $this->assertContains('phone', self::invokePrivate('getSensitiveFields', 'admin_user'));
        $this->assertContains('email', self::invokePrivate('getSensitiveFields', 'admin_user'));
        $this->assertContains('id_card', self::invokePrivate('getSensitiveFields', 'admin_user'));
    }

    public function test_pdf_generates_nonempty_file(): void
    {
        $response = (new ExportController())->pdf(self::makeRequest([
            'type'  => 'table',
            'title' => '测试导出',
            'data'  => [
                'columns' => ['姓名'],
                'rows'    => [['张三']],
            ],
        ]));
        $file = $response->file['file'] ?? null;
        $this->assertNotNull($file, '下载响应应携带文件路径');
        $this->assertFileExists($file);
        $this->assertGreaterThan(0, filesize($file));
        $this->assertStringStartsWith('%PDF', file_get_contents($file));
        @unlink($file);
    }

    public function test_excel_generates_nonempty_file(): void
    {
        if (!self::$dbAvailable) {
            $this->markTestSkipped('DB 不可用');
        }
        $response = (new ExportController())->excel(self::makeRequest([
            'table'   => 'admin_user',
            'columns' => ['id', 'username'],
        ]));
        $file = $response->file['file'] ?? null;
        $this->assertNotNull($file, '下载响应应携带文件路径');
        $this->assertFileExists($file);
        $this->assertGreaterThan(0, filesize($file));
        $this->assertStringStartsWith('PK', file_get_contents($file)); // zip 魔数
        @unlink($file);
    }
}
