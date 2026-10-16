<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * 创建/确保默认管理员账号（一键部署用，幂等）
 *
 * 用法: php scripts/create_admin.php --username=admin --password=Admin@123456
 *   容器内: docker compose exec -T app php /app/scripts/create_admin.php ...
 *   - 密码校验与登录口同一规则源（app\admin\validate\PasswordRule），不满足直接失败退出
 *   - 用户名已存在时跳过（exit 0），不覆盖现有密码
 *
 * 背景: 一键部署（scripts/deploy.sh）的库由 install.sql 导入，不含任何管理员种子；
 *       本脚本补上文档承诺的默认管理员（README/INSTALL「默认账户」），
 *       密码可用 .env 的 ADMIN_INITIAL_PASSWORD 覆盖。
 */

use app\admin\validate\PasswordRule;
use app\common\SnowflakeService;

$baseDir = __DIR__ . '/..';

require_once $baseDir . '/vendor/autoload.php';

if (class_exists('Dotenv\Dotenv') && file_exists($baseDir . '/.env')) {
    \Dotenv\Dotenv::createUnsafeMutable($baseDir)->load();
}

\Webman\Config::clear();
support\App::loadAllConfig(['route']);
support\bootstrap\Db::start(null);

$options = getopt('', ['username::', 'password::']);
$username = trim((string) ($options['username'] ?? 'admin'));
$password = (string) ($options['password'] ?? '');

if ($username === '' || $password === '') {
    fwrite(STDERR, "用法: php create_admin.php --username=admin --password=<密码>\n");
    exit(1);
}

// 与登录口同一规则：不满足的密码建出来也登不上，直接拒（防「一键装完就登录失败」）
$ruleError = PasswordRule::check($password);
if ($ruleError !== null) {
    fwrite(STDERR, "错误: 密码不满足登录规则（{$ruleError}），创建后将无法登录。\n");
    exit(1);
}

$exists = support\Db::table('management_admin_user')->where('username', $username)->count();
if ($exists > 0) {
    echo "管理员 '{$username}' 已存在，跳过创建。\n";
    exit(0);
}

$id = SnowflakeService::generate();
$now = date('Y-m-d H:i:s');

// AdminUser 模型挂载了 scout 观察者，CLI 无 ES 客户端会崩，故用原生 insert（同 demo_data.php）
support\Db::table('management_admin_user')->insert([
    'id'         => $id,
    'username'   => $username,
    'password'   => password_hash($password, PASSWORD_BCRYPT),
    'real_name'  => '系统管理员',
    'status'     => 1,
    'created_at' => $now,
    'updated_at' => $now,
]);

// install.sql 种子角色：超级管理员（与安装向导 InstallController::SUPER_ADMIN_ROLE_ID 同值）
support\Db::table('management_admin_user_role')->insert([
    'user_id' => $id,
    'role_id' => 10000000000000001,
]);

echo "默认管理员 '{$username}' 创建成功（超级管理员）。请登录后立即修改密码。\n";
