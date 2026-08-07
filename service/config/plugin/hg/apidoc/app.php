<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

return [
    'enable'  => true,
    'apidoc' => [
        // 文档标题
        'title'              => '物业管理系统 - 业主端API',
        // 文档描述
        'desc'               => '业主端（业务端）全部接口文档，按功能分组。',
        // 应用/版本分组
        // 每个 app 通过显式 controllers 列表限定所属控制器（与类上 @Apidoc\Group 注解一致），
        // 避免 hg/apidoc 按 path 目录扫描时把全部控制器重复塞进每个分组
        'apps'           => [
            [
                'title' => '公开接口（认证/验证码）',
                'path'  => 'app\api\v1\controller',
                'key'   => 'public',
                'controllers' => ['AuthController', 'CaptchaController'],
            ],
            [
                'title' => '首页与房产',
                'path'  => 'app\api\v1\controller',
                'key'   => 'home',
                'controllers' => ['HomeController', 'RoomController'],
            ],
            [
                'title' => '费用管理（账单/缴费/统计）',
                'path'  => 'app\api\v1\controller',
                'key'   => 'fee',
                'controllers' => ['FeeController'],
            ],
            [
                'title' => '报修管理',
                'path'  => 'app\api\v1\controller',
                'key'   => 'repair',
                'controllers' => ['RepairController'],
            ],
            [
                'title' => '投诉建议与公告',
                'path'  => 'app\api\v1\controller',
                'key'   => 'feedback',
                'controllers' => ['AnnouncementController', 'ComplaintController'],
            ],
            [
                'title' => '停车与访客',
                'path'  => 'app\api\v1\controller',
                'key'   => 'parking',
                'controllers' => ['ParkingController', 'VisitorController'],
            ],
            [
                'title' => '社区活动',
                'path'  => 'app\api\v1\controller',
                'key'   => 'activity',
                'controllers' => ['ActivityController'],
            ],
            [
                'title' => '个人中心',
                'path'  => 'app\api\v1\controller',
                'key'   => 'profile',
                'controllers' => ['ProfileController'],
            ],
            [
                'title' => '扩展功能（通知/投票/商城/问答/人脸）',
                'path'  => 'app\api\v1\controller',
                'key'   => 'extensions',
                'controllers' => ['FaceController', 'KnowledgeController', 'MallController', 'NotificationController', 'VoteController'],
            ],
        ],
        // 通用注释定义
        'definitions'        => "app\common\Definitions",
        // 自动生成URL规则
        'auto_url' => [
            'letter_rule' => "lcfirst",
            'prefix'      => "",
        ],
        'auto_register_routes' => false,
        'cache'              => ['enable' => false],
        'auth'               => [
            'enable'     => false,
            'password'   => "123456",
            'secret_key' => "apidoc#hg_code",
            'expire'     => 24*60*60
        ],
        // 全局请求Header
        'params' => [
            'header' => [
                ['name' => 'Authorization', 'type' => 'string', 'require' => true, 'desc' => '身份令牌 Bearer Token（公开接口不需要）'],
                ['name' => 'API-Version',   'type' => 'string', 'require' => false, 'desc' => 'API版本，默认v1'],
                ['name' => 'Accept-Language','type' => 'string', 'require' => false, 'desc' => '语言: zh-CN / en-US'],
                ['name' => 'X-Client-Platform','type' => 'string', 'require' => false, 'desc' => '客户端平台: web/ios/android/harmonyos'],
            ],
            'query' => [],
            'body'  => [],
        ],
        // 全局响应体
        'responses' => [
            'success' => [
                ['name' => 'code',    'desc' => '业务代码 0=成功', 'type' => 'int',    'require' => 1],
                ['name' => 'message', 'desc' => '业务信息',       'type' => 'string', 'require' => 1],
                ['name' => 'data',    'desc' => '业务数据',       'main' => true,     'type' => 'object', 'require' => 1],
            ],
            'error' => [
                ['name' => 'code',    'desc' => '错误码',   'type' => 'int',    'require' => 1],
                ['name' => 'message', 'desc' => '错误信息', 'type' => 'string', 'require' => 1],
            ]
        ],
        'responses_status' => [
            ['name' => '200', 'desc' => '请求成功'],
            ['name' => '400', 'desc' => '请求参数错误'],
            ['name' => '401', 'desc' => '登录令牌无效或已过期'],
            ['name' => '403', 'desc' => '无权限访问'],
            ['name' => '404', 'desc' => '资源不存在'],
            ['name' => '422', 'desc' => '参数验证失败'],
            ['name' => '429', 'desc' => '请求过于频繁'],
            ['name' => '500', 'desc' => '服务端内部错误'],
        ],
        'default_author'     => 'erik <erik@erik.xyz>',
        'default_method'     => 'GET',
        'allowCrossDomain'   => false,
        'ignored_annitation' => [],
        'ignored_methods'    => ['__construct', '__get', '__set'],
        'database'           => [],
        'docs'               => [],
        'generator'          => []
    ]
];
