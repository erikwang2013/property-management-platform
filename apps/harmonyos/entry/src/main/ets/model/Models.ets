/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

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
