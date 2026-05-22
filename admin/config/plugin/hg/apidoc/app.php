<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

return [
    'enable' => true,
    'apidoc' => [
        'title' => '物业管理系统 - 管理端API',
        'desc'  => '管理员端接口文档，按功能分组。',
        'apps'  => [
            ['title'=>'通用接口（认证/验证码/健康检查）',   'path'=>'app\api\v1\controller',    'key'=>'common'],
            ['title'=>'仪表盘与运维（Dashbord/Metrics/导出）','path'=>'app\admin\controller',    'key'=>'dashboard'],
            ['title'=>'系统管理（用户/角色/权限/配置/日志）','path'=>'app\admin\controller',    'key'=>'system'],
            ['title'=>'物业管理·核心（小区/楼栋/房产/业主/费用/报修/公告）','path'=>'app\admin\controller','key'=>'property-core'],
            ['title'=>'物业管理·辅助（停车/设备/投诉/访客/合同/财务）','path'=>'app\admin\controller','key'=>'property-aux'],
            ['title'=>'物业管理·高级（巡逻/保洁/绿化/活动/能耗/员工）','path'=>'app\admin\controller','key'=>'property-adv'],
            ['title'=>'扩展功能（通知/审批/支付/投票/SLA/催缴/巡检/商城/人脸/集团/问答）','path'=>'app\admin\controller','key'=>'extensions'],
        ],
        'definitions' => "app\common\Definitions",
        'auto_url' => ['letter_rule' => 'lcfirst', 'prefix' => ''],
        'auto_register_routes' => false,
        'cache'   => ['enable' => false],
        'auth'    => ['enable' => false, 'password' => '123456', 'secret_key' => 'apidoc#hg_code', 'expire' => 86400],
        'params'  => [
            'header' => [
                ['name'=>'Authorization','type'=>'string','require'=>true,'desc'=>'身份令牌 Bearer Token'],
                ['name'=>'API-Version','type'=>'string','require'=>false,'desc'=>'API版本，默认v1'],
                ['name'=>'Accept-Language','type'=>'string','require'=>false,'desc'=>'语言: zh-CN / en-US'],
            ],
            'query' => [],
            'body'  => [],
        ],
        'responses' => [
            'success' => [
                ['name'=>'code','desc'=>'业务代码 0=成功','type'=>'int','require'=>1],
                ['name'=>'message','desc'=>'业务信息','type'=>'string','require'=>1],
                ['name'=>'data','desc'=>'业务数据','main'=>true,'type'=>'object','require'=>1],
            ],
            'error' => [
                ['name'=>'code','desc'=>'错误码','type'=>'int','require'=>1],
                ['name'=>'message','desc'=>'错误信息','type'=>'string','require'=>1],
            ]
        ],
        'responses_status' => [
            ['name'=>'200','desc'=>'请求成功'],
            ['name'=>'400','desc'=>'请求参数错误'],
            ['name'=>'401','desc'=>'Token无效或已过期'],
            ['name'=>'403','desc'=>'无权限访问'],
            ['name'=>'404','desc'=>'资源不存在'],
            ['name'=>'422','desc'=>'参数验证失败'],
            ['name'=>'429','desc'=>'请求过于频繁'],
            ['name'=>'500','desc'=>'服务端错误'],
        ],
        'default_author'   => 'erik <erik@erik.xyz>',
        'default_method'   => 'GET',
        'allowCrossDomain' => false,
        'ignored_annitation' => [],
        'ignored_methods'    => ['__construct','__get','__set'],
        'database' => [],
        'docs'     => [],
        'generator'=> []
    ]
];
