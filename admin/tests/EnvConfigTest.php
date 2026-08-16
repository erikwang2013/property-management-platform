<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\Test;

class EnvConfigTest extends TestCase
{
    protected function setUp(): void
    {
        if (file_exists(__DIR__ . '/../.env')) {
            $dotenv = \Dotenv\Dotenv::createUnsafeImmutable(__DIR__ . '/..');
            $dotenv->safeLoad();
        }
    }

    #[Test]
    public function env_file_exists(): void
    {
        $this->assertFileExists(__DIR__ . '/../.env');
    }

    #[Test]
    public function env_example_file_exists(): void
    {
        $this->assertFileExists(__DIR__ . '/../.env.example');
    }

    #[Test]
    public function getenv_reads_env_variables(): void
    {
        $this->assertNotEmpty(getenv('APP_NAME'), 'APP_NAME 应有值');
        $this->assertNotEmpty(getenv('JWT_SECRET_KEY'), 'JWT_SECRET_KEY 应有值');
        $this->assertNotEmpty(getenv('DB_HOST'), 'DB_HOST 应有值');
    }

    #[Test]
    public function getenv_fallback_pattern_works(): void
    {
        // 存在的变量返回实际值
        $val = getenv('APP_NAME') ?: 'DEFAULT_APP';
        $this->assertNotEquals('DEFAULT_APP', $val);

        // 不存在的变量返回默认值
        $val2 = getenv('THIS_VAR_DOES_NOT_EXIST_XYZ') ?: 'FALLBACK_OK';
        $this->assertEquals('FALLBACK_OK', $val2);
    }

    #[Test]
    public function config_env_keys_exist_in_dotenv(): void
    {
        // 收集 .env 中的键
        $envContent = file_get_contents(__DIR__ . '/../.env');
        preg_match_all('/^([A-Z_][A-Z0-9_]*)=/m', $envContent, $matches);
        $envKeys = array_flip($matches[1]);

        // 检查每个配置文件中的 getenv 键
        $configFiles = glob(__DIR__ . '/../config/*.php');
        $missingKeys = [];

        foreach ($configFiles as $file) {
            $content = file_get_contents($file);
            preg_match_all("/getenv\('([A-Z_][A-Z0-9_]*)'\)/", $content, $m);
            foreach ($m[1] as $key) {
                if (!isset($envKeys[$key])) {
                    $missingKeys[] = basename($file) . ": $key";
                }
            }
        }

        $this->assertEmpty($missingKeys, '以下 env key 在 .env 中缺失: ' . implode(', ', $missingKeys));
    }

    #[Test]
    public function critical_config_types(): void
    {
        $this->assertIsNumeric(getenv('JWT_TTL') ?: 7200, 'JWT_TTL 应为数字');
        $this->assertIsNumeric(getenv('DB_PORT') ?: 3306, 'DB_PORT 应为数字');
        $this->assertIsString(getenv('JWT_SECRET_KEY') ?: 'x', 'JWT_SECRET_KEY 应为字符串');
        $this->assertIsString(getenv('HASHIDS_SALT') ?: 'x', 'HASHIDS_SALT 应为字符串');
    }

    #[Test]
    public function install_wizard_keys_exist_in_env_example(): void
    {
        // 安装向导 writeEnvFile 依赖模板中的这些键（存在则替换，缺失则追加到末尾），
        // 模板缺键会让生成的 .env 结构不完整，此处保证 .env.example 键位齐全
        $wizardKeys = [
            'PAYMENT_ENABLED', 'PAYMENT_ENVIRONMENT', 'PAYMENT_NOTIFY_HOST',
            'WECHAT_PAY_ENABLED', 'WECHAT_PAY_APP_ID', 'WECHAT_PAY_MCH_ID', 'WECHAT_PAY_API_V3_KEY',
            'ALIPAY_ENABLED', 'ALIPAY_APP_ID', 'ALIPAY_PRIVATE_KEY',
            'OPENSEARCH_HTTP_HOST', 'OPENSEARCH_USERNAME', 'OPENSEARCH_PASSWORD',
        ];
        $example = file_get_contents(__DIR__ . '/../.env.example');
        preg_match_all('/^([A-Z_][A-Z0-9_]*)=/m', $example, $matches);
        $exampleKeys = array_flip($matches[1]);

        $missing = array_values(array_filter($wizardKeys, fn(string $k) => !isset($exampleKeys[$k])));
        $this->assertEmpty($missing, '向导写入键在 .env.example 中缺失: ' . implode(', ', $missing));
    }
}
