<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * 全局中间件配置
 *
 * 以下中间件对所有请求生效，按注册顺序依次执行。
 * 执行顺序: Cors → SecurityFilter → RateLimit → ApiVersion → {路由组中间件} → Controller
 */

return [
    // webman v2: 全局中间件必须挂在 '@' 键下（v1 的扁平数组会抛 "Bad middleware config"）
    '@' => [
        app\middleware\Cors::class,
        app\middleware\SecurityFilter::class,
        app\middleware\RateLimit::class,
        app\middleware\MetricsCollector::class,
    ],
];
