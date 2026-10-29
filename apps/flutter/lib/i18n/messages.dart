/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:get/get.dart';

/// 国际化翻译消息
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh_CN': {
      // 通用
      'app_name': '物业管理平台',
      'login': '登录',
      'register': '注册',
      'logout': '退出登录',
      'confirm': '确认',
      'cancel': '取消',
      'save': '保存',
      'delete': '删除',
      'edit': '编辑',
      'search': '搜索',
      'reset': '重置',
      'submit': '提交',
      'back': '返回',
      'loading': '加载中...',
      'no_data': '暂无数据',
      'operation_success': '操作成功',
      'operation_failed': '操作失败',
      'confirm_delete': '确认删除？此操作不可撤销',
      'export_excel': '导出Excel',
      'export_pdf': '导出PDF',

      // 登录页
      'phone_hint': '请输入手机号',
      'password_hint': '请输入密码',
      'captcha_hint': '请按顺序点击',
      'login_btn': '登 录',
      'no_account': '还没有账号？立即注册',
      'has_account': '已有账号？去登录',

      // 首页
      'home': '首页',
      'my_rooms': '我的房产',
      'pending_payment': '待缴费',
      'latest_announcements': '最新公告',

      // 房产
      'room_number': '房号',
      'room_area': '面积',
      'room_floor': '楼层',
      'room_orientation': '朝向',
      'room_decoration': '装修',
      'room_status': '状态',
      'room_detail': '房产详情',

      // 费用
      'fee_management': '费用管理',
      'fee_bills': '账单列表',
      'fee_payment': '缴费记录',
      'fee_pay': '在线缴费',
      'fee_statistics': '费用统计',
      'bill_detail': '账单详情',
      'fee_type': '费用类型',
      'payment_success': '支付成功',
      'bill_number': '账单编号',
      'bill_amount': '账单金额',
      'bill_status': '状态',
      'bill_unpaid': '未缴',
      'bill_partial': '部分缴',
      'bill_paid': '已缴',
      'bill_overdue': '逾期',
      'bill_due_date': '截止日期',
      'payment_method': '支付方式',
      'payment_amount': '支付金额',
      'payment_time': '支付时间',
      'wechat_pay': '微信支付',
      'alipay': '支付宝',
      'confirm_pay': '确认支付',
      'password_confirm': '请输入密码确认',



      // 公告
      'announcement': '公告通知',
      'announcement_list': '公告列表',
      'announcement_detail': '公告详情',
      'published_at': '发布时间',

      // 个人中心
      'profile': '个人中心',
      'profile_info': '个人信息',
      'change_password': '修改密码',
      'old_password': '旧密码',
      'new_password': '新密码',
      'confirm_password': '确认密码',
      'name': '姓名',
      'phone': '手机号',
      'email': '邮箱',
      'gender': '性别',
      'birthday': '生日',
      'gender_unknown': '未知',
      'gender_male': '男',
      'gender_female': '女',
    },
    'en': {
      // General
      'app_name': 'Property Management',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'reset': 'Reset',
      'submit': 'Submit',
      'back': 'Back',
      'loading': 'Loading...',
      'no_data': 'No data',
      'operation_success': 'Operation successful',
      'operation_failed': 'Operation failed',
      'confirm_delete': 'Confirm delete? This action cannot be undone',
      'export_excel': 'Export Excel',
      'export_pdf': 'Export PDF',

      // Login
      'phone_hint': 'Enter phone number',
      'password_hint': 'Enter password',
      'captcha_hint': 'Click in order',
      'login_btn': 'Login',
      'no_account': 'No account? Register',
      'has_account': 'Already have an account? Login',

      // Home
      'home': 'Home',
      'my_rooms': 'My Properties',
      'pending_payment': 'Pending Payment',
      'latest_announcements': 'Latest Announcements',

      // Room
      'room_number': 'Room No.',
      'room_area': 'Area',
      'room_floor': 'Floor',
      'room_orientation': 'Orientation',
      'room_decoration': 'Decoration',
      'room_status': 'Status',
      'room_detail': 'Property Details',

      // Fee
      'fee_management': 'Fee Management',
      'fee_bills': 'Bills',
      'fee_payment': 'Payment Records',
      'fee_pay': 'Online Payment',
      'fee_statistics': 'Fee Statistics',
      'bill_detail': 'Bill Details',
      'fee_type': 'Fee Type',
      'payment_success': 'Payment Successful',
      'bill_number': 'Bill No.',
      'bill_amount': 'Amount',
      'bill_status': 'Status',
      'bill_unpaid': 'Unpaid',
      'bill_partial': 'Partial',
      'bill_paid': 'Paid',
      'bill_overdue': 'Overdue',
      'bill_due_date': 'Due Date',
      'payment_method': 'Method',
      'payment_amount': 'Amount',
      'payment_time': 'Time',
      'wechat_pay': 'WeChat Pay',
      'alipay': 'Alipay',
      'confirm_pay': 'Confirm Payment',
      'password_confirm': 'Enter password to confirm',



      // Announcement
      'announcement': 'Announcements',
      'announcement_list': 'Announcements',
      'announcement_detail': 'Details',
      'published_at': 'Published',

      // Profile
      'profile': 'Profile',
      'profile_info': 'Personal Info',
      'change_password': 'Change Password',
      'old_password': 'Old Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'name': 'Name',
      'phone': 'Phone',
      'email': 'Email',
      'gender': 'Gender',
      'birthday': 'Birthday',
      'gender_unknown': 'Unknown',
      'gender_male': 'Male',
      'gender_female': 'Female',
    },
  };
}
