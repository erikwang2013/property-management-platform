<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * 支付凭证集中配置
 *
 * 所有渠道凭证通过 .env 注入，本文件只做读取与转发。
 * 沙箱与生产环境切换：PAYMENT_ENVIRONMENT=sandbox|production，
 * 沙箱下自动使用微信支付沙箱网关 / 支付宝沙箱网关（openapi.alipaydev.com）。
 */

return [
    // 总开关：false 时下单/回调/退款/对账全部拒绝并提示未配置
    'enabled'     => (bool) env('PAYMENT_ENABLED', false),
    // 环境: sandbox=沙箱 / production=生产
    'environment' => env('PAYMENT_ENVIRONMENT', 'sandbox'),
    // 回调公网地址前缀（不带末尾斜杠），用于拼装 notify_url
    'notify_host' => env('PAYMENT_NOTIFY_HOST', ''),
    // HTTP 请求超时（秒）
    'timeout'     => (int) env('PAYMENT_TIMEOUT', 10),

    'channels' => [
        'wechat' => [
            'enabled'       => (bool) env('WECHAT_PAY_ENABLED', false),
            'app_id'        => env('WECHAT_PAY_APP_ID', ''),
            'mch_id'        => env('WECHAT_PAY_MCH_ID', ''),
            // API v3 密钥（商户平台设置 > API安全）
            'api_v3_key'    => env('WECHAT_PAY_API_V3_KEY', ''),
            // 商户证书序列号（证书详情里查看）
            'serial_no'     => env('WECHAT_PAY_SERIAL_NO', ''),
            // 商户 API 私钥 PEM 文件路径
            'private_key'   => env('WECHAT_PAY_PRIVATE_KEY', ''),
            // 微信支付平台证书 PEM 文件路径（用于回调验签）
            'platform_cert' => env('WECHAT_PAY_PLATFORM_CERT', ''),
        ],
        'alipay' => [
            'enabled'          => (bool) env('ALIPAY_ENABLED', false),
            'app_id'           => env('ALIPAY_APP_ID', ''),
            // 应用私钥 PEM（RSA2）
            'private_key'      => env('ALIPAY_PRIVATE_KEY', ''),
            // 支付宝公钥 PEM（沙箱用沙箱公钥，生产用支付宝公钥）
            'alipay_public_key' => env('ALIPAY_PUBLIC_KEY', ''),
        ],
    ],

    // 对账与订单参数
    'reconcile' => [
        // 默认回溯天数
        'default_days'   => 7,
        // 支付订单有效分钟数（超时自动关闭）
        'expire_minutes' => 15,
    ],
];
