// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

/** 行数据类型 —— 字段以各控制器 index()/show() 的实际返回为准 */

export interface Community {
  id: string
  name: string
  address: string
  city: string
  building_count: number
  room_count: number
  property_company: string
  status: number
  created_at: string
}

export interface TreeUnit {
  id: string
  name: string
  type: 'unit'
  children: TreeRoom[]
}

export interface TreeRoom {
  id: string
  name: string
  type: 'room'
  status: number
}

export interface TreeBuilding {
  id: string
  name: string
  type: 'building'
  children: TreeUnit[]
}

export interface TreeCommunity {
  id: string
  name: string
  type: 'community'
  children: TreeBuilding[]
}

export interface Room {
  id: string
  community_id: string
  building_id: string
  unit_id: string
  room_number: string
  floor: number
  room_type_id: string
  area_indoor: number | null
  area_total: number | null
  orientation: string
  usage_type: number
  status: number
  created_at: string
}

export interface Owner {
  id: string
  name: string
  phone: string
  email: string
  gender: number
  status: number
  check_in_date: string
  created_at: string
}

export interface FeeType {
  id: string
  name: string
  category: number
  unit_price: number | string
  unit_type: number
  cycle_type: number
  is_required: number
  sort: number
  created_at: string
}

export interface FeeBill {
  id: string
  room_id: string
  owner_id: string
  fee_type_id: string
  bill_number: string
  amount: number | string
  paid_amount: number | string
  late_fee: number | string
  start_date: string
  end_date: string
  due_date: string
  status: number
  paid_at: string
  created_at: string
}

export interface FeePayment {
  id: string
  bill_id: string
  owner_id: string
  payment_number: string
  amount: number | string
  payment_method: number
  payment_channel: number
  paid_at: string
  operator_id: number
  receipt_url: string
  remark: string
  created_at: string
}

export interface RepairProgress {
  id: string
  /** ⚠️ 这里存的是**操作管理员 id**（addProgress 写入 adminId），不是员工 id，别拿去查名册 */
  staff_id: number
  status_from: number
  status_to: number
  remark: string
  images: string[] | null
  created_at: string
}

export interface Repair {
  id: string
  order_number: string
  room_id: string
  owner_id: string
  contact_phone: string
  category: number
  urgency: number
  description: string
  status: number
  /** 2026-10-03 起后端返回 hashid（未分配为 ''），可直接用于派单表单回填 */
  staff_id: string
  /** 后端一次 join 带出的姓名（未分配为 ''）；列表与详情都显示它，不要显示 staff_id */
  staff_name: string
  completed_at: string
  created_at: string
}

export interface RepairDetail extends Repair {
  images: string[] | null
  scheduled_at: string
  rating: number
  feedback: string
  progress: RepairProgress[]
}

export interface Complaint {
  id: string
  owner_id: string
  room_id: string
  type: number
  /** 数值枚举 1=服务态度 … 7=其他（model 里 casts 成 integer，此前误标成 string） */
  category: number
  title: string
  status: number
  is_anonymous: number
  handler_id: string
  handled_at: string
  satisfaction: number
  created_at: string
}

export interface ComplaintDetail extends Complaint {
  content: string
  images: string[] | null
  handler_remark: string
  visitor_id: string
  visitor_remark: string
  visitor_at: string
}

export interface AdminUserRow {
  id: string
  username: string
  real_name: string
  email: string
  phone: string
  status: number
  last_login_at: string | null
  created_at: string
}

export interface Role {
  id: string
  name: string
  slug: string
  description: string
  status: number
  users_count: number
  /** RoleController::index 走 toArray()，created_at 是 Eloquent 的 ISO8601（带 T），列里做一次格式化 */
  created_at: string
}

export interface Permission {
  id: string
  parent_id: number
  name: string
  slug: string
  type: number
  icon: string
  path: string
  sort: number
  children?: Permission[]
}

export interface SystemConfigItem {
  id: string
  group: string
  key: string
  value: string
  type: string
  description: string
  /** 后端 getConfigList 走 toArray()，updated_at 有返回 */
  updated_at?: string
}

export interface LogRow {
  id: string
  user_name: string
  action: string
  method: string
  path: string
  ip: string
  source: string
  /** 请求参数：LogController::index 走 toArray()，该列是 JSON 字符串（详情抽屉里格式化展示） */
  input?: string
  created_at: string
}

export interface StatCard {
  label: string
  value: string
  icon?: string
  color?: string
  trend?: number | null
}

export interface DashboardData {
  stats: StatCard[]
  trends: { dates: string[]; series: { name: string; data: number[]; color?: string }[] }
  distribution: { user_status: { name: string; value: number }[] }
  recent_logs: LogRow[]
}

export interface ReportData {
  summary: {
    total_billed: number
    total_paid: number
    arrears: number
    collection_rate: number
    total_rooms: number
    occupied_rooms: number
    occupancy_rate: number
    pending_repairs: number
    pending_complaints: number
    visitors_today: number
    parking_now: number
  }
  income_trend: { month: string; total: number }[]
  expense_trend: { month: string; total: number }[]
  payment_methods: { name: string; count: number; total: number }[]
  repair_status: { status: number; count: number }[]
  complaint_status: { status: number; count: number }[]
  visitor_status: { status: number; count: number }[]
  repair_category: { category: number; count: number }[]
  arrears_ranking: { owner_name: string; owner_phone: string; room_name: string; arrears: number }[]
}
