// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 枚举字典：取值以 docs/install.sql 的列注释 + 控制器 apidoc 注解为准
// （Flutter 版页面里内联的那套标签与后端控制器逻辑不一致，此处以后端为准）。
import { Option, Query } from './types';

export interface Dict {
  [key: number]: string;
}

/** 通用：字典 → 下拉选项 */
export function options(dict: Dict): Option[] {
  return Object.entries(dict).map(([value, label]) => ({ label, value: Number(value) }));
}

/**
 * 通用：字典 → 徽标映射。
 * 颜色一律用 ng-zorro 预设名（success / warning / error / processing / default），**不再用十六进制**：
 * ① 预设名渲染为「浅底彩字」，自定义 hex 是「实色底白字」，表格里密集出现后者视觉噪音大（team-lead 2026-10-03 裁定，两端统一取前者）；
 * ② 预设名走 --ant-*-color 变量，色相仍由 src/theme/_tokens.scss 指向设计色板，改色板时两端一起动。
 * 分类类字典（无褒贬含义：分类/用途/性别/渠道…）不传 colors，一律中性 default —— 按值轮换色板无信息量且是两端分叉的主要来源。
 * 五档语义与 React 端 STATUS_MAPS 同档位（同一状态两端同色档）。
 */
export function tags(dict: Dict, colors: Record<number, string> = {}): Record<number, { text: string; color: string }> {
  const out: Record<number, { text: string; color: string }> = {};
  for (const [value, text] of Object.entries(dict)) {
    out[Number(value)] = { text, color: colors[Number(value)] ?? 'default' };
  }
  return out;
}

// —— 通用状态 ——
export const ENABLE: Dict = { 0: '禁用', 1: '启用' };
export const ENABLE_TAGS = tags(ENABLE, { 0: 'error', 1: 'success' });

export const NORMAL: Dict = { 0: '停用', 1: '正常' };
export const NORMAL_TAGS = tags(NORMAL, { 0: 'error', 1: 'success' });

// —— 小区 / 房产 ——
export const ROOM_STATUS: Dict = { 0: '空置', 1: '已售', 2: '出租', 3: '自住' };
export const ROOM_STATUS_TAGS = tags(ROOM_STATUS, {
  0: 'default',
  1: 'success',
  2: 'processing',
  3: 'processing',
});

export const USAGE_TYPE: Dict = { 1: '住宅', 2: '商业', 3: '办公', 4: '仓储' };
// 分类类：中性
export const USAGE_TYPE_TAGS = tags(USAGE_TYPE);
export const DECORATION: Dict = { 1: '毛坯', 2: '简装', 3: '精装', 4: '豪装' };

// —— 业主 ——
export const OWNER_STATUS: Dict = { 0: '迁出', 1: '入住' };
export const OWNER_STATUS_TAGS = tags(OWNER_STATUS, { 0: 'default', 1: 'success' });
export const GENDER: Dict = { 0: '未知', 1: '男', 2: '女' };
// 分类类：中性
export const GENDER_TAGS = tags(GENDER);

// —— 账单 ——
export const BILL_STATUS: Dict = { 0: '未缴', 1: '部分缴', 2: '已缴', 3: '逾期', 4: '豁免' };
export const BILL_STATUS_TAGS = tags(BILL_STATUS, {
  0: 'default',
  1: 'warning',
  2: 'success',
  3: 'error',
  4: 'default',
});

// —— 缴费 ——
export const PAYMENT_METHOD: Dict = {
  1: '微信',
  2: '支付宝',
  3: '现金',
  4: '银行转账',
  5: '刷卡',
};
export const PAYMENT_CHANNEL: Dict = { 1: '在线', 2: '线下' };
// 分类类：中性
export const PAYMENT_CHANNEL_TAGS = tags(PAYMENT_CHANNEL);
export const PAYMENT_METHOD_TAGS = tags(PAYMENT_METHOD);

// —— 报修 ——
export const REPAIR_STATUS: Dict = {
  0: '待派单',
  1: '已派单',
  2: '维修中',
  3: '已完成',
  4: '已评价',
  5: '已取消',
};
export const REPAIR_STATUS_TAGS = tags(REPAIR_STATUS, {
  0: 'default',
  1: 'processing',
  2: 'warning',
  3: 'success',
  4: 'success',
  5: 'default',
});
export const REPAIR_CATEGORY: Dict = {
  1: '水电',
  2: '门窗',
  3: '墙面地面',
  4: '管道',
  5: '家电',
  6: '电梯',
  7: '公共设施',
  8: '其他',
};
// 分类类：中性
export const REPAIR_CATEGORY_TAGS = tags(REPAIR_CATEGORY);
export const URGENCY: Dict = { 1: '普通', 2: '紧急', 3: '非常紧急' };
export const URGENCY_TAGS = tags(URGENCY, { 1: 'default', 2: 'warning', 3: 'error' });

// —— 投诉 ——
// 编号以 install.sql:974 的列注释为准（`0=待处理 1=处理中 2=已处理 3=已回访 4=已关闭`）。
// 此前两端按旧守卫读成 `1=待处理 2=处理中`、与 SQL 分叉；2026-10-03 后端改的是**守卫**
// （handle 收 0 置 1、visit 收 1 置 3），编号回到 SQL，前端随之改回 —— 前端 / SQL / 守卫三者一致。
export const COMPLAINT_STATUS: Dict = {
  0: '待处理',
  1: '处理中',
  2: '已处理',
  3: '已回访',
  4: '已关闭',
};
export const COMPLAINT_STATUS_TAGS = tags(COMPLAINT_STATUS, {
  0: 'warning',
  1: 'processing',
  2: 'success',
  3: 'success',
  4: 'default',
});
/** 后端 handle 守卫 status===0（置 1）；visit 守卫 status===1（置 3） */
export const COMPLAINT_HANDLEABLE = 0;
export const COMPLAINT_VISITABLE = 1;

// 有褒贬（非分类类），保留语义色
export const COMPLAINT_TYPE: Dict = { 1: '投诉', 2: '建议', 3: '表扬' };
export const COMPLAINT_TYPE_TAGS = tags(COMPLAINT_TYPE, {
  1: 'error',
  2: 'warning',
  3: 'success',
});
export const COMPLAINT_CATEGORY: Dict = {
  1: '服务态度',
  2: '环境卫生',
  3: '安全管理',
  4: '设施维护',
  5: '噪音',
  6: '违建',
  7: '其他',
};
// 分类类：中性
export const COMPLAINT_CATEGORY_TAGS = tags(COMPLAINT_CATEGORY);
export const ANONYMOUS: Dict = { 0: '实名', 1: '匿名' };
export const ANONYMOUS_TAGS = tags(ANONYMOUS);

// —— 访客 ——
// SQL 1010（management_visitor.status）。本端没有访客列表页，这张表只服务报表页的「访客状态」饼图
export const VISITOR_STATUS: Dict = { 0: '已预约', 1: '已到访', 2: '已离开', 3: '已取消' };

// —— 权限 ——
export const PERMISSION_TYPE: Dict = { 1: '菜单', 2: '按钮', 3: 'API接口' };
// 分类类：中性
export const PERMISSION_TYPE_TAGS = tags(PERMISSION_TYPE);

// —— 操作日志 ——
/**
 * 操作来源端 → 展示名。取值见 docs/install.sql:560（`source` 列的八值枚举），
 * 后端 OperationLog::detectSource() 原样返回小写标识，**不要**把 `harmonyos` 这类裸标识直接显示给用户。
 * 品牌名保留官方拼写（macOS/Windows/Linux 无通用中文名），有通行中文名的用中文。
 */
export const LOG_SOURCES: Record<string, string> = {
  web: '网页端',
  ios: 'iOS',
  ipados: 'iPadOS',
  android: '安卓',
  harmonyos: '鸿蒙',
  windows: 'Windows',
  macos: 'macOS',
  linux: 'Linux',
};

/** 去掉空值后的查询对象（搜索区常用） */
export function clean(query: Query): Query {
  const out: Query = {};
  for (const [k, v] of Object.entries(query)) {
    if (v !== null && v !== undefined && v !== '') out[k] = v;
  }
  return out;
}
