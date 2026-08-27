<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

// 熔断器配置：按调用点分组，覆盖 CircuitBreaker 默认参数
// failure_threshold: 窗口内失败多少次触发熔断（open）
// window: 失败计数窗口（秒）
// timeout: open 保持多久后放行 1 个探测请求（half_open）
return [
    // 支付网关（prepay/refund/queryOrder）：外部依赖，失败累计熔断
    'payment' => [
        'failure_threshold' => 5,
        'window'            => 60,
        'timeout'           => 30,
    ],
    // 业务回调投递：偶发网络抖动多，阈值放宽，避免误熔断
    'webhook' => [
        'failure_threshold' => 10,
        'window'            => 60,
        'timeout'           => 15,
    ],
];
