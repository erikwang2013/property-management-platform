/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

export interface ClickPoint {
  x: number;
  y: number;
}

export interface LoginRequest {
  phone: string;
  password: string;
  captcha_key: string;
  clicks: Array<ClickPoint>;
}

export interface RepairRequest {
  category: number;
  urgency: number;
  description: string;
  room_id?: string;
}

export interface PasswordRequest {
  old_password: string;
  new_password: string;
}

export interface Owner {
  id: string;
  name: string;
  phone: string;
  gender: number;
}

export interface Room {
  id: string;
  room_number: string;
  floor: number;
  area_total: number;
  status: number;
  community_name: string;
}

export interface FeeBill {
  id: string;
  bill_number: string;
  amount: number;
  paid_amount: number;
  unpaid: number;
  due_date: string;
  status: number;
  fee_type_name: string;
  room_number: string;
}

export interface RepairOrder {
  id: string;
  order_number: string;
  category: number;
  urgency: number;
  description: string;
  status: number;
  room_number: string;
}

export interface Announcement {
  id: string;
  title: string;
  category: number;
  published_at: string;
}

export interface Visitor {
  id: string;
  visitor_name: string;
  visitor_phone: string;
  plate_number: string;
  visitor_count: number;
  purpose: string;
  expected_start: string;
  expected_end: string;
  pass_code: string;
  status: number;
  created_at: string;
}

export interface ParkingSpace {
  id: string;
  space_number: string;
  space_type: number;
  area: number;
  status: number;
  fee_monthly: number;
}

export interface ParkingVehicle {
  id: string;
  plate_number: string;
  vehicle_brand: string;
  vehicle_color: string;
  vehicle_type: number;
  end_date: string;
  status: number;
  space: ParkingSpace | null;
}

export interface ParkingRecord {
  id: string;
  plate_number: string;
  entry_time: string;
  exit_time: string;
  duration: number;
  fee: number;
}
