<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace support;

use Illuminate\Database\Capsule\Manager as Capsule;

/**
 * webman v2 框架已移除 support\Db 门面，此文件恢复 v1 兼容层。
 * 静态实例由 support\bootstrap\Db::start() 中的 setAsGlobal() 注入，
 * table()/select() 走 Manager 静态方法，raw() 等经 __callStatic 转发到连接。
 */
class Db extends Capsule
{
}
