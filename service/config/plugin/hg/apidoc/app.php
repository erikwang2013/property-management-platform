<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
return [
 'enable'=>true,
 'apidoc'=>[
  'title'=>'物业管理系统 - 业主端API',
  'desc'=>'业主端（业务端）接口文档，按功能分组。',
  'apps'=>[
   ['title'=>'公开接口（认证/验证码）','path'=>'app\api\v1\controller','key'=>'public'],
   ['title'=>'首页与房产','path'=>'app\api\v1\controller','key'=>'home'],
   ['title'=>'费用管理（账单/缴费/统计）','path'=>'app\api\v1\controller','key'=>'fee'],
   ['title'=>'报修管理','path'=>'app\api\v1\controller','key'=>'repair'],
   ['title'=>'投诉建议与公告','path'=>'app\api\v1\controller','key'=>'feedback'],
   ['title'=>'停车与访客','path'=>'app\api\v1\controller','key'=>'parking'],
   ['title'=>'社区活动','path'=>'app\api\v1\controller','key'=>'activity'],
   ['title'=>'个人中心','path'=>'app\api\v1\controller','key'=>'profile'],
   ['title'=>'扩展功能（通知/投票/商城/问答/人脸）','path'=>'app\api\v1\controller','key'=>'extensions'],
  ],
  'definitions'=>'app\common\Definitions',
  'auto_url'=>['letter_rule'=>'lcfirst','prefix'=>''],
  'auto_register_routes'=>false,
  'cache'=>['enable'=>false],
  'auth'=>['enable'=>false,'password'=>'123456','secret_key'=>'apidoc#hg_code','expire'=>86400],
  'params'=>['header'=>[
   ['name'=>'Authorization','type'=>'string','require'=>true,'desc'=>'身份令牌 Bearer Token（公开接口不需要）'],
   ['name'=>'API-Version','type'=>'string','require'=>false,'desc'=>'API版本，默认v1'],
   ['name'=>'Accept-Language','type'=>'string','require'=>false,'desc'=>'语言: zh-CN / en-US'],
   ['name'=>'X-Client-Platform','type'=>'string','require'=>false,'desc'=>'客户端平台: web/ios/android/harmonyos'],
  ],'query'=>[],'body'=>[]],
  'responses'=>[
   'success'=>[['name'=>'code','desc'=>'业务代码 0=成功','type'=>'int','require'=>1],['name'=>'message','desc'=>'业务信息','type'=>'string','require'=>1],['name'=>'data','desc'=>'业务数据','main'=>true,'type'=>'object','require'=>1]],
   'error'=>[['name'=>'code','desc'=>'错误码','type'=>'int','require'=>1],['name'=>'message','desc'=>'错误信息','type'=>'string','require'=>1]]
  ],
  'responses_status'=>[['name'=>'200','desc'=>'请求成功'],['name'=>'400','desc'=>'请求参数错误'],['name'=>'401','desc'=>'Token无效或已过期'],['name'=>'403','desc'=>'无权限访问'],['name'=>'404','desc'=>'资源不存在'],['name'=>'422','desc'=>'参数验证失败'],['name'=>'429','desc'=>'请求过于频繁'],['name'=>'500','desc'=>'服务端错误']],
  'default_author'=>'erik <erik@erik.xyz>',
  'default_method'=>'GET',
  'allowCrossDomain'=>false,
  'ignored_annitation'=>[],
  'ignored_methods'=>['__construct','__get','__set'],
  'database'=>[],'docs'=>[],'generator'=>[]
 ]
];
