<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\ImportController;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;
use Webman\Http\UploadFile;

class ImportControllerTest extends TestCase
{
    private static bool $dbAvailable = false;
    private static string $tmpDir = '';

    public static function setUpBeforeClass(): void
    {
        self::$tmpDir = sys_get_temp_dir() . '/import_test_' . getmypid();
        if (!is_dir(self::$tmpDir)) {
            mkdir(self::$tmpDir, 0755, true);
        }
        try {
            Db::select('select 1');
            self::$dbAvailable = true;
        } catch (\Throwable) {
            self::$dbAvailable = false;
        }
    }

    public static function tearDownAfterClass(): void
    {
        foreach (glob(self::$tmpDir . '/*') ?: [] as $f) {
            @unlink($f);
        }
        @rmdir(self::$tmpDir);
    }

    /** 生成真实 xlsx 文件，供 IOFactory 解析 */
    private static function makeXlsx(array $rows): string
    {
        $spreadsheet = new Spreadsheet();
        $spreadsheet->getActiveSheet()->fromArray($rows);
        $path = self::$tmpDir . '/test_' . uniqid() . '.xlsx';
        (new Xlsx($spreadsheet))->save($path);
        return $path;
    }

    private static function makeRequest(?UploadFile $file): Request
    {
        return new class($file) extends Request {
            private ?UploadFile $upload;

            public function __construct(?UploadFile $upload)
            {
                $this->upload = $upload;
            }

            public function file(?string $name = null): array|null|UploadFile
            {
                return $this->upload;
            }

            public function input(string $name, mixed $default = null)
            {
                return $default;
            }
        };
    }

    private static function call(?UploadFile $file): array
    {
        $response = (new ImportController())->users(self::makeRequest($file));
        return json_decode($response->rawBody(), true);
    }

    public function test_missing_file_rejected(): void
    {
        $body = self::call(null);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请上传 Excel 文件', $body['message']);
    }

    public function test_wrong_extension_rejected(): void
    {
        $path = self::$tmpDir . '/test.csv';
        file_put_contents($path, 'a,b,c');
        $file = new UploadFile($path, 'test.csv', 'text/csv', UPLOAD_ERR_OK);
        $body = self::call($file);
        $this->assertSame(422, $body['code']);
        $this->assertSame('仅支持 .xlsx 或 .xls 文件', $body['message']);
    }

    public function test_oversize_file_rejected(): void
    {
        // 稀疏文件：只写尾部 1 字节，文件大小为 11MB，避开真实写入
        $path = self::$tmpDir . '/big.xlsx';
        $fp = fopen($path, 'w');
        fseek($fp, 11 * 1024 * 1024);
        fwrite($fp, 'x');
        fclose($fp);
        $file = new UploadFile($path, 'big.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', UPLOAD_ERR_OK);
        $body = self::call($file);
        $this->assertSame(422, $body['code']);
        $this->assertSame('文件大小不能超过 10MB', $body['message']);
    }

    public function test_empty_sheet_rejected(): void
    {
        $path = self::makeXlsx([['username', 'password']]); // 仅表头一行
        $file = new UploadFile($path, 'empty.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', UPLOAD_ERR_OK);
        $body = self::call($file);
        $this->assertSame(422, $body['code']);
        $this->assertSame('Excel 文件无数据', $body['message']);
    }

    public function test_missing_required_column_rejected(): void
    {
        $path = self::makeXlsx([
            ['username', 'password'], // 缺 real_name
            ['u1', 'pass123'],
        ]);
        $file = new UploadFile($path, 'bad.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', UPLOAD_ERR_OK);
        $body = self::call($file);
        $this->assertSame(422, $body['code']);
        $this->assertSame('缺少必填列: real_name', $body['message']);
    }

    public function test_header_normalization_and_row_validation(): void
    {
        // 表头大小写/空格混合仍应通过列映射；空用户名行应记入失败明细（DB 之前即判定）
        $path = self::makeXlsx([
            [' Username ', 'Password', 'Real_Name'],
            ['', 'pass123', '张三'],
        ]);
        $file = new UploadFile($path, 'ok.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', UPLOAD_ERR_OK);
        $body = self::call($file);
        $this->assertSame(0, $body['code']);
        $this->assertSame(1, $body['data']['total']);
        $this->assertSame(0, $body['data']['success']);
        $this->assertSame(1, $body['data']['failed']);
        $this->assertSame('用户名为空', $body['data']['errors'][0]['reason']);
        $this->assertSame(2, $body['data']['errors'][0]['row']);
    }

    public function test_duplicate_username_row_rejected(): void
    {
        if (!self::$dbAvailable) {
            $this->markTestSkipped('DB 不可用');
        }
        $path = self::makeXlsx([
            ['username', 'password', 'real_name', 'phone', 'email'],
            ['admin', 'Pass1234!', '管理员', '13800000000', 'a@b.c'], // 种子数据中 admin 已存在
        ]);
        $file = new UploadFile($path, 'dup.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', UPLOAD_ERR_OK);
        $body = self::call($file);
        $this->assertSame(0, $body['code']);
        $this->assertSame(1, $body['data']['failed']);
        $this->assertStringContainsString('已存在', $body['data']['errors'][0]['reason']);
    }
}
