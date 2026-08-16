<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * 商业版本配置（与 docs/EDITIONS.md 对应）
 * - lite: 基础版，仅第 1 批核心模块
 * - standard: 标准版，含第 2 批辅助模块
 * - full: 完整版，全部模块（默认）
 *
 * 通过环境变量 EDITIONS 覆盖，路由分组按版本条件注册。
 */
return [
    'default' => env('EDITIONS', 'full'),
    'levels'  => ['lite' => 1, 'standard' => 2, 'full' => 3],
];
