<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use support\Request;
use support\Response;
use PDO;
use PDOException;

class InstallController
{
    private const LOCK_FILE = '.installed';
    private const SQL_PATH = '/../docs/install.sql';
    private const SUPER_ADMIN_ROLE_ID = 10000000000000001;

    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/api/install")
     */
    public function index(Request $request): Response
    {
        if ($this->isInstalled()) {
            return view('install/installed');
        }
        return $this->renderStep1();
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/api/install")
     */
    public function store(Request $request): Response
    {
        if ($this->isInstalled()) {
            return view('install/installed');
        }

        $step = $request->post('_step', '1');

        if ($step === '2') {
            return $this->processStep1($request);
        }
        if ($step === '3') {
            return $this->processStep2($request);
        }

        return $this->renderStep1([], '未知的安装步骤');
    }

    private function processStep1(Request $request): Response
    {
        $db = [
            'host'     => trim($request->post('host', '')),
            'port'     => trim($request->post('port', '')),
            'database' => trim($request->post('database', '')),
            'username' => trim($request->post('username', '')),
            'password' => $request->post('password', ''),
        ];

        $errors = [];
        if ($db['host'] === '') $errors[] = '请输入数据库主机地址';
        if ($db['port'] === '' || !ctype_digit($db['port'])) $errors[] = '请输入有效的端口号';
        if ($db['database'] === '') $errors[] = '请输入数据库名';
        if ($db['username'] === '') $errors[] = '请输入数据库用户名';

        if ($errors) {
            return $this->renderStep1($db, implode('；', $errors));
        }

        return $this->renderStep2($db);
    }

    private function processStep2(Request $request): Response
    {
        $db = [
            'host'     => trim($request->post('host', '')),
            'port'     => trim($request->post('port', '')),
            'database' => trim($request->post('database', '')),
            'username' => trim($request->post('db_username', '')),
            'password' => $request->post('db_password', ''),
        ];

        $admin = [
            'admin_username' => trim($request->post('admin_username', '')),
            'admin_password' => $request->post('admin_password', ''),
        ];
        $confirm = $request->post('admin_password_confirm', '');

        $errors = [];
        if (mb_strlen($admin['admin_username']) < 3) $errors[] = '管理员用户名至少3个字符';
        // 密码强度与登录校验保持一致：8-32 位 + 大小写字母 + 数字 + 特殊字符
        if (strlen($admin['admin_password']) < 8 || strlen($admin['admin_password']) > 32) {
            $errors[] = '管理员密码长度需 8-32 位';
        }
        if (!preg_match('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/', $admin['admin_password'])) {
            $errors[] = '管理员密码需包含大小写字母、数字和特殊字符(@$!%*?&)';
        }
        if ($admin['admin_password'] !== $confirm) $errors[] = '两次输入的密码不一致';

        if ($errors) {
            return $this->renderStep2($db, $admin, implode('；', $errors));
        }

        if ($request->post('_confirm') === '1') {
            return $this->executeAndRender($db, $admin);
        }

        return $this->renderStep3($db, $admin, false, [], true);
    }

    private function renderStep1(array $old = [], string $error = ''): Response
    {
        return view('install/step1', ['old' => $old, 'error' => $error]);
    }

    private function renderStep2(array $dbConfig, array $old = [], string $error = ''): Response
    {
        return view('install/step2', [
            'dbConfig' => $dbConfig,
            'old'      => $old,
            'error'    => $error,
        ]);
    }

    private function renderStep3(array $dbConfig, array $adminConfig, bool $executed, array $results, bool $allSuccess): Response
    {
        $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8787';
        $loginUrl = "$scheme://$host/api/auth/login";

        return view('install/step3', [
            'dbConfig'    => $dbConfig,
            'adminConfig' => $adminConfig,
            'executed'    => $executed,
            'results'     => $results,
            'allSuccess'  => $allSuccess,
            'loginUrl'    => $loginUrl,
        ]);
    }

    private function executeAndRender(array $dbConfig, array $adminConfig): Response
    {
        $results = $this->executeInstall($dbConfig, $adminConfig);
        $allSuccess = true;
        foreach ($results as $r) {
            if ($r['status'] !== 'success') {
                $allSuccess = false;
                break;
            }
        }
        return $this->renderStep3($dbConfig, $adminConfig, true, $results, $allSuccess);
    }

    private function executeInstall(array $dbConfig, array $adminConfig): array
    {
        $results = [];

        $conn = $this->testConnection($dbConfig);
        $results[] = $conn;
        if ($conn['status'] === 'error') return $results;
        $pdo = $conn['pdo'];

        $env = $this->writeEnvFile($dbConfig);
        $results[] = $env;
        if ($env['status'] === 'error') return $results;

        $sql = $this->importSql($pdo);
        $results[] = $sql;
        if ($sql['status'] === 'error') return $results;

        $admin = $this->createAdminUser($pdo, $adminConfig);
        $results[] = $admin;

        $lock = $this->setLockFile();
        $results[] = $lock;

        return $results;
    }

    private function testConnection(array $dbConfig): array
    {
        try {
            $dsn = "mysql:host={$dbConfig['host']};port={$dbConfig['port']};dbname={$dbConfig['database']};charset=utf8mb4";
            $pdo = new PDO($dsn, $dbConfig['username'], $dbConfig['password'], [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8mb4'",
            ]);
            $pdo->query('SELECT 1');
            return ['title' => '数据库连接', 'status' => 'success', 'message' => '连接成功', 'pdo' => $pdo];
        } catch (PDOException $e) {
            $msg = match (true) {
                str_contains($e->getMessage(), 'Unknown database') => "数据库 '{$dbConfig['database']}' 不存在，请先创建",
                str_contains($e->getMessage(), 'Access denied')     => '用户名或密码错误',
                str_contains($e->getMessage(), 'Connection refused') => '连接被拒绝，请检查主机和端口',
                default => $e->getMessage(),
            };
            return ['title' => '数据库连接', 'status' => 'error', 'message' => $msg];
        }
    }

    private function writeEnvFile(array $dbConfig): array
    {
        $envPath = base_path() . '/.env';
        if (!file_exists($envPath)) {
            $examplePath = base_path() . '/.env.example';
            if (file_exists($examplePath)) {
                copy($examplePath, $envPath);
            } else {
                return ['title' => '.env 配置', 'status' => 'error', 'message' => '.env 和 .env.example 文件均不存在'];
            }
        }

        $contents = file_get_contents($envPath);
        if ($contents === false) {
            return ['title' => '.env 配置', 'status' => 'error', 'message' => '无法读取 .env 文件'];
        }

        $replacements = [
            '/^DB_HOST=.*$/m'     => "DB_HOST={$dbConfig['host']}",
            '/^DB_PORT=.*$/m'     => "DB_PORT={$dbConfig['port']}",
            '/^DB_DATABASE=.*$/m' => "DB_DATABASE={$dbConfig['database']}",
            '/^DB_USERNAME=.*$/m' => "DB_USERNAME={$dbConfig['username']}",
            '/^DB_PASSWORD=.*$/m' => "DB_PASSWORD={$dbConfig['password']}",
        ];

        $contents = preg_replace(array_keys($replacements), array_values($replacements), $contents);

        if (file_put_contents($envPath, $contents, LOCK_EX) === false) {
            return ['title' => '.env 配置', 'status' => 'error', 'message' => '无法写入 .env 文件'];
        }

        return ['title' => '.env 配置', 'status' => 'success', 'message' => '数据库配置已写入 .env'];
    }

    private function importSql(PDO $pdo): array
    {
        $sqlPath = realpath(base_path() . self::SQL_PATH);
        if (!$sqlPath || !file_exists($sqlPath)) {
            return ['title' => '数据表导入', 'status' => 'error', 'message' => '找不到 docs/install.sql'];
        }

        $sql = file_get_contents($sqlPath);
        $sql = preg_replace('/^--.*$/m', '', $sql);
        $statements = array_values(array_filter(
            array_map('trim', explode(';', $sql)),
            fn(string $s): bool => $s !== ''
        ));

        $total = count($statements);
        $failed = 0;
        $lastError = '';
        foreach ($statements as $stmt) {
            try {
                $pdo->exec($stmt);
            } catch (PDOException $e) {
                $failed++;
                $lastError = $e->getMessage();
            }
        }

        if ($failed > 0) {
            return ['title' => '数据表导入', 'status' => 'error', 'message' => "{$failed}/{$total} 条语句执行失败：" . $lastError];
        }

        return ['title' => '数据表导入', 'status' => 'success', 'message' => "共 {$total} 条语句，全部执行成功"];
    }

    private function createAdminUser(PDO $pdo, array $adminConfig): array
    {
        try {
            $id = \app\common\SnowflakeService::generate();
            $password = password_hash($adminConfig['admin_password'], PASSWORD_BCRYPT);
            $username = $adminConfig['admin_username'];

            $pdo->prepare(
                'INSERT INTO `erik_admin_user` (`id`, `username`, `password`, `real_name`, `status`, `created_at`, `updated_at`)
                 VALUES (:id, :username, :password, :real_name, 1, NOW(), NOW())'
            )->execute([
                'id'       => $id,
                'username' => $username,
                'password' => $password,
                'real_name' => '系统管理员',
            ]);

            $pdo->prepare(
                'INSERT INTO `erik_admin_user_role` (`user_id`, `role_id`) VALUES (:uid, :rid)'
            )->execute(['uid' => $id, 'rid' => self::SUPER_ADMIN_ROLE_ID]);

            return ['title' => '管理员账户', 'status' => 'success', 'message' => "用户 '{$username}' 已创建，已授予超级管理员角色"];
        } catch (PDOException $e) {
            $msg = $e->getMessage();
            if (str_contains($msg, 'Duplicate entry')) {
                $msg = "用户名 '{$username}' 已存在";
            }
            return ['title' => '管理员账户', 'status' => 'error', 'message' => $msg];
        }
    }

    private function setLockFile(): array
    {
        $lockPath = public_path() . '/' . self::LOCK_FILE;
        if (file_put_contents($lockPath, date('Y-m-d H:i:s') . ' — installed', LOCK_EX) === false) {
            return ['title' => '安装锁定', 'status' => 'error', 'message' => '无法创建锁定文件，请检查 public/ 目录权限'];
        }
        return ['title' => '安装锁定', 'status' => 'success', 'message' => 'public/.installed 已创建'];
    }

    private function isInstalled(): bool
    {
        return file_exists(public_path() . '/' . self::LOCK_FILE);
    }
}
