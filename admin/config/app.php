<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * This file is part of webman.
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the MIT-LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @author    walkor<walkor@workerman.net>
 * @copyright walkor<walkor@workerman.net>
 * @link      http://www.workerman.net/
 * @license   http://www.opensource.org/licenses/mit-license.php MIT License
 */

use support\Request;

return [
    // 调试模式由环境变量 APP_DEBUG 控制（生产环境必须设为 false，避免堆栈泄漏到客户端）
    'debug' => (bool) getenv('APP_DEBUG'),
    // E_DEPRECATED 不转为异常：hg/apidoc 注解类在 PHP 8.3 产生 dynamic property 弃用通知，
    // webman 默认将弃用转 ErrorException 会导致 /apidoc 接口 500
    'error_reporting' => E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED,
    'default_timezone' => 'Asia/Shanghai',
    'request_class' => Request::class,
    'public_path' => base_path() . DIRECTORY_SEPARATOR . 'public',
    'runtime_path' => base_path(false) . DIRECTORY_SEPARATOR . 'runtime',
    'controller_suffix' => 'Controller',
    'controller_reuse' => false,
];
