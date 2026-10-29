<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * 中文语言包 — 管理端
 */

return [
    // 通用
    'success' => '操作成功',
    'fail' => '操作失败',
    'not_found' => '资源不存在',
    'unauthorized' => '未登录',
    'forbidden' => '无权限',
    'token_expired' => 'Token已过期或无效',
    'token_invalid' => 'Token已失效，请重新登录',
    'too_many_requests' => '请求过于频繁，请稍后再试',
    'account_locked' => '账号已被锁定，请稍后再试',
    'account_disabled' => '账号已被禁用',
    'server_error' => '服务器内部错误',
    'validation_failed' => '参数验证失败',
    'password_required' => '敏感操作需要输入密码确认',
    'password_wrong' => '密码验证失败',
    'delete_success' => '删除成功',
    'create_success' => '创建成功',
    'update_success' => '更新成功',

    // 认证
    'auth.login_success' => '登录成功',
    'auth.username_required' => '用户名和密码不能为空',
    'auth.credentials_wrong' => '用户名或密码错误',
    'auth.captcha_wrong' => '验证码错误',
    'auth.logout_success' => '已退出',
    'auth.password_min_length' => '密码至少6位',
    'auth.old_password_wrong' => '旧密码错误',
    'auth.password_changed' => '密码修改成功',
    'auth.phone_exists' => '该手机号已注册',
    'auth.phone_password_required' => '手机号和密码不能为空',
    'auth.register_success' => '注册成功',

    // 小区管理
    'community.name_required' => '小区名称不能为空',
    'community.not_found' => '小区不存在',

    // 业主管理
    'owner.not_found' => '业主不存在',

    // 费用管理
    'fee.bill_not_found' => '账单不存在',
    'fee.bill_paid' => '该账单已缴费或已豁免',
    'fee.pay_success' => '缴费成功',
    'fee.invalid_bill' => '账单信息无效',

    // 文件
    'file.upload_success' => '上传成功',
    'file.upload_failed' => '上传失败',

    // 导出
    'export.excel_success' => 'Excel导出成功',
    'export.pdf_success' => 'PDF导出成功',
];
