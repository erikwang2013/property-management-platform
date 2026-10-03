// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 通用列表页 / 表单弹窗的描述符：13 个模块只描述列与字段，不重复写分页逻辑。
import { Observable } from 'rxjs';

import { Option, PageResult, Query } from '../api/types';

export interface TagSpec {
  text: string;
  color: string;
}

export type CellKind = 'text' | 'strong' | 'tag' | 'money' | 'datetime' | 'bool';

export interface Column {
  key: string;
  title: string;
  width?: string;
  align?: 'left' | 'center' | 'right';
  /** 单行省略号 + title 悬浮全文；长文本列（如问题描述）必须开，否则行高会被撑到数百像素 */
  ellipsis?: boolean;
  kind?: CellKind;
  /** kind: 'tag' 时用于把值映射成带色徽标 */
  map?: Record<string | number, TagSpec>;
  /** 展示 hashid 关联字段时把值换成可读文案（如 room_id → 房号）；无命中则原样显示 hashid */
  lookup?: (value: string) => string | undefined;
  /** 组合单元格：从整行取值（账单的「费用周期」= 起 ~ 止）；给了它就无视 key 的取值，与 React 侧 render 同义 */
  render?: (row: Record<string, unknown>) => string;
}

export interface FilterField {
  key: string;
  label: string;
  kind?: 'text' | 'select' | 'date';
  placeholder?: string;
  /** 函数形式：支持 signal 延迟加载的下拉项 */
  options?: () => Option[];
  width?: string;
}

export interface RowAction<T> {
  label: string;
  danger?: boolean;
  hidden?: (row: T) => boolean;
  run: (row: T) => unknown | Promise<unknown>;
}

/** 列表数据源：返回归一化后的行集 */
export type Loader<T> = (query: Query, page: number, pageSize: number) => Observable<PageResult<T>>;

export interface FormField {
  key: string;
  label: string;
  kind?: 'text' | 'password' | 'number' | 'textarea' | 'select' | 'date' | 'switch';
  required?: boolean;
  placeholder?: string;
  hint?: string;
  options?: () => Option[];
  /** 编辑态下禁用（后端不可改的字段，如房产所属小区） */
  immutable?: boolean;
  /** 占满两列（默认单列，textarea 自动占满） */
  wide?: boolean;
  min?: number;
  max?: number;
  step?: number;
}

/** 表单提交值 */
export type FormValue = Record<string, string | number | boolean | null>;
