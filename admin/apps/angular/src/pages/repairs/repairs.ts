// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 报修管理：详情（只读抽屉）+ 派单 + 进度上报。
// staff_id 自 2026-10-03 起为 **hashid**（后端已改），列表另回 staff_name 供直接展示。
import { Component, computed, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzDescriptionsModule } from 'ng-zorro-antd/descriptions';
import { NzDrawerModule } from 'ng-zorro-antd/drawer';
import { NzTagModule } from 'ng-zorro-antd/tag';
import { NzTimelineModule } from 'ng-zorro-antd/timeline';
import { firstValueFrom } from 'rxjs';

import { API, ApiService } from '../../api/api.service';
import {
  options,
  REPAIR_CATEGORY,
  REPAIR_STATUS,
  REPAIR_STATUS_TAGS,
  URGENCY,
  URGENCY_TAGS,
} from '../../api/dict';
import { EMPTY_TREE_INDEX, indexRoomTree, TreeNode, TreeIndex } from '../../api/room-tree';
import { Option, Query } from '../../api/types';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import {
  Column,
  FilterField,
  FormField,
  FormValue,
  RowAction,
} from '../../components/types';

interface RepairRow extends Record<string, unknown> {
  id: string;
  order_number: string;
  room_id: string;
  owner_id: string;
  contact_phone: string;
  category: number;
  urgency: number;
  description: string;
  status: number;
  staff_id: string;
  staff_name: string;
  completed_at: string;
  created_at: string;
}

/** /admin/staff 的行（派单表单的人员下拉数据源） */
interface StaffRow {
  id: string;
  name: string;
  job_title: string;
  /** 0 离职 / 1 在职 / 2 休假 —— 离职不给派新单（与 React 同口径） */
  status: number;
}

/** /admin/owner 的行（建单表单的报修人下拉数据源） */
interface OwnerRow {
  id: string;
  name: string;
  phone: string;
}

/** 进度记录：staff_id 是**操作管理员 id**（后端 addProgress 写 adminId），不是员工 hashid，不展示 */
interface RepairProgress {
  id: string;
  remark: string;
  status_from: number;
  status_to: number;
  created_at: string;
}

/** GET /admin/repair/{hashid} 的详情（字段以后端 show() 实际返回为准） */
interface RepairDetail {
  id: string;
  order_number: string;
  room_id: string;
  contact_phone: string;
  category: number;
  urgency: number;
  description: string;
  /** `images` 列可空（RepairOrder 是 json cast，NULL → null），故类型可空、模板里用 `?.` */
  images: string[] | null;
  scheduled_at: string;
  status: number;
  staff_name: string;
  completed_at: string;
  rating: number | null;
  feedback: string;
  progress: RepairProgress[];
}

@Component({
  selector: 'xz-repairs',
  imports: [
    DataTableComponent,
    FormModalComponent,
    NzButtonModule,
    NzDescriptionsModule,
    NzDrawerModule,
    NzTagModule,
    NzTimelineModule,
  ],
  templateUrl: './repairs.html',
  // 详情抽屉的图片缩略图局部样式（避免为这几条规则新建 scss 文件；时间线小标题已提为全局 .xz-track-title）
  styles: `
    .shot {
      display: inline-block;
      margin: 0 8px 8px 0;
    }
    .shot img {
      width: 72px;
      height: 72px;
      object-fit: cover;
      border-radius: var(--xz-radius-tag);
    }
  `,
})
export class RepairsComponent {
  private readonly api = inject(ApiService);

  /** 房产树索引：报修列表只回 room_id(hashid)，取一次树建映射（与 React 的 `tree.roomName` 同源） */
  private readonly treeIndex = signal<TreeIndex>(EMPTY_TREE_INDEX);
  /** 派单表单的人员下拉（/admin/staff 的 hashid + 姓名） */
  private readonly staffs = signal<Option[]>([]);
  /** 建单表单的报修人下拉（/admin/owner 的 hashid + 姓名 手机号，与 React 的 useOwners 同格式） */
  private readonly owners = signal<Option[]>([]);

  constructor() {
    // 与 React 侧同一数据源（tree.roomName）；拉不到只是房产列回落显示 hashid，不打断列表
    this.api.get<TreeNode[]>(API.roomTree).subscribe({
      next: (nodes) => this.treeIndex.set(indexRoomTree(nodes)),
      error: () => void 0,
    });
    // ponytail: 取前 200 名建下拉；员工规模更大时应换成远程搜索
    this.api.getPage<StaffRow>(API.staff, {}, 1, 200).subscribe({
      next: (page) =>
        this.staffs.set(
          page.rows
            // 离职（status 0）不派新单；休假（2）仍可派 —— 与 React 同口径
            .filter((s) => s.status !== 0)
            .map((s) => ({ label: `${s.name}${s.job_title ? `（${s.job_title}）` : ''}`, value: s.id })),
        ),
      // 拉不到只是下拉为空，不影响列表与详情
      error: () => void 0,
    });
    // ponytail: 同 staffs，取前 200 名；业主规模更大时应换成远程搜索
    this.api.getPage<OwnerRow>(API.owner, {}, 1, 200).subscribe({
      next: (page) => this.owners.set(page.rows.map((o) => ({ label: `${o.name} ${o.phone}`, value: o.id }))),
      error: () => void 0,
    });
  }

  // —— 详情抽屉（只读）：字段与 React 侧 Drawer 对齐，动作仍走下面两个弹窗 ——
  protected readonly detailOpen = signal(false);
  protected readonly detail = signal<RepairDetail | null>(null);

  protected readonly openDetail = (row: RepairRow): void => {
    this.detail.set(null);
    this.detailOpen.set(true);
    this.api.get<RepairDetail>(API.repairDetail(row.id)).subscribe({
      next: (data) => this.detail.set(data),
      error: () => this.detail.set(null),
    });
  };

  /** 字典取值，未知枚举回落原值（与 React 侧 statusText 同语义） */
  protected readonly statusText = (v: number): string => REPAIR_STATUS[v] ?? String(v);
  protected readonly categoryText = (v: number): string => REPAIR_CATEGORY[v] ?? String(v);
  protected readonly urgencyText = (v: number): string => URGENCY[v] ?? String(v);
  protected readonly statusTags = REPAIR_STATUS_TAGS;

  /** 详情里的房产名：查不到回落 hashid（与列表列同一映射） */
  protected readonly roomName = (id: string): string => this.treeIndex().rooms.get(id) || id;

  /** 与 React 侧同一句：`<原状态> → <新状态>　<备注>（<时间>）` */
  protected readonly progressText = (p: RepairProgress): string =>
    `${this.statusText(p.status_from)} → ${this.statusText(p.status_to)}　${p.remark || ''}（${p.created_at}）`;

  /** 评价：有文字用文字，只有星级用「N 星」，都没有给破折号（与 React 侧同口径） */
  protected readonly ratingText = (d: RepairDetail): string =>
    d.feedback || (d.rating ? `${d.rating} 星` : '—');

  protected readonly refresh = signal(0);
  /** 建单 / 派单 / 进度上报共用同一个表单弹窗；模式与当前行在打开前落定 */
  protected readonly actionOpen = signal(false);
  protected readonly actionMode = signal<'create' | 'assign' | 'progress'>('assign');
  protected readonly actionRow = signal<FormValue | null>(null);

  /** 建单表单的房产下拉：复用已拉的房产树（Map 保序 = 小区→楼栋→单元→房号），不多发一次请求 */
  protected readonly roomOptions = computed<Option[]>(() =>
    Array.from(this.treeIndex().rooms, ([value, label]) => ({ label, value })),
  );

  /** 列集与顺序由两端统一裁定：工单号 · 房产 · 类别 · 紧急度 · 问题描述 · 状态 · 维修人员 · 完成时间 · 创建时间 · 操作 */
  protected readonly columns: Column[] = [
    { key: 'order_number', title: '工单号', kind: 'strong', width: '140px' },
    // 列表只回 room_id(hashid)，与 React 侧 `tree.roomName(id) || id` 同思路，查不到就显示 hashid
    { key: 'room_id', title: '房产', width: '150px', lookup: (v) => this.treeIndex().rooms.get(v) },
    // 属性值不是状态 → 纯文本（同 React 的 statusText）
    { key: 'category', title: '类别', width: '84px', lookup: (v) => REPAIR_CATEGORY[Number(v)] ?? '—' },
    { key: 'urgency', title: '紧急度', kind: 'tag', map: URGENCY_TAGS, width: '84px' },
    // 长文本：定宽 + 单行省略（React 版同为 220px + ellipsis），否则该列会被挤成竖排、行高被撑到数百像素
    { key: 'description', title: '问题描述', width: '220px', ellipsis: true },
    { key: 'status', title: '状态', kind: 'tag', map: REPAIR_STATUS_TAGS, width: '90px' },
    // 后端已 join 出 staff_name；未分配为空串 → cellText 统一成「—」（不需要列级 lookup）
    { key: 'staff_name', title: '维修人员', width: '100px' },
    { key: 'completed_at', title: '完成时间', width: '150px' },
    { key: 'created_at', title: '创建时间', width: '150px' },
  ];

  /** 筛选区文案与列标题统一（工单号 / 类别），别一处叫报修编号、一处叫工单号 */
  protected readonly filters: FilterField[] = [
    { key: 'keyword', label: '工单号', placeholder: '输入工单号搜索' },
    { key: 'status', label: '状态', kind: 'select', options: () => options(REPAIR_STATUS) },
    { key: 'category', label: '类别', kind: 'select', options: () => options(REPAIR_CATEGORY) },
  ];

  protected readonly actionFields = computed<FormField[]>(() => {
    // 建单：字段与 React 的 createFields 同集同序（后端 store() 只要 room_id + contact_phone，其余可选）
    if (this.actionMode() === 'create') {
      return [
        {
          key: 'room_id',
          label: '报修房产',
          kind: 'select',
          required: true,
          options: () => this.roomOptions(),
          hint: '来自 /admin/room/tree（提交房间 hashid）',
        },
        {
          key: 'owner_id',
          label: '报修人',
          kind: 'select',
          options: () => this.owners(),
        },
        { key: 'contact_phone', label: '联系电话', required: true },
        { key: 'category', label: '分类', kind: 'select', options: () => options(REPAIR_CATEGORY) },
        { key: 'urgency', label: '紧急程度', kind: 'select', options: () => options(URGENCY) },
        { key: 'scheduled_at', label: '预约上门', kind: 'date' },
        { key: 'description', label: '问题描述', kind: 'textarea' },
      ];
    }
    return this.actionMode() === 'assign'
      ? [
          {
            key: 'staff_id',
            label: '维修人员',
            kind: 'select',
            required: true,
            options: () => this.staffs(),
            hint: '来自员工名册 /admin/staff，已过滤离职员工（提交 hashid）',
          },
          { key: 'remark', label: '派单说明', kind: 'textarea' },
        ]
      : [
          {
            key: 'status',
            label: '变更后状态',
            kind: 'select',
            required: true,
            options: () => options(REPAIR_STATUS),
          },
          // 进度说明必填：React 侧同为 required（后端不校验，但留痕是这条记录的唯一意义）
          { key: 'remark', label: '进度说明', kind: 'textarea', required: true },
        ];
  });

  /** 标题带工单号（与 React 同格式），便于同时开多个工单时对上号。
   *  措辞按规范 §5 的「进度上报」（team-lead 2026-10-03 裁定：以规格为准，React 侧同桌跟改）。 */
  protected readonly actionTitle = computed(() => {
    const mode = this.actionMode();
    if (mode === 'create') return '新建报修单';
    const base = mode === 'assign' ? '派单' : '进度上报';
    const no = String(this.actionRow()?.['order_number'] ?? '');
    return no ? `${base} · ${no}` : base;
  });

  /** 已完成 / 已评价 / 已取消的单子不再需要派单与进度上报 */
  private readonly settled = (row: RepairRow): boolean => row.status >= 3 || row.status === 5;

  protected readonly rowActions: RowAction<RepairRow>[] = [
    { label: '详情', run: (row) => this.openDetail(row) },
    { label: '派单', hidden: (row) => this.settled(row), run: (row) => this.start('assign', row) },
    {
      label: '进度',
      hidden: (row) => this.settled(row),
      run: (row) => this.start('progress', row),
    },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getPage<RepairRow>(API.repair, query, page, size);

  private start(mode: 'assign' | 'progress', row: RepairRow): void {
    this.actionMode.set(mode);
    // values 只用于预填当前值，提交体在 submit 里按模式重建
    this.actionRow.set(row as unknown as FormValue);
    this.actionOpen.set(true);
  }

  /** 建单不针对某一行，清掉 actionRow 免得带上上一单的预填值 */
  protected readonly create = (): void => {
    this.actionMode.set('create');
    this.actionRow.set(null);
    this.actionOpen.set(true);
  };

  protected readonly actionSubmit = async (value: FormValue): Promise<unknown> => {
    if (this.actionMode() === 'create') {
      // 空值一律不发：后端把空串当值写库（空串写 datetime/number 列会报类型错，README 已记）
      const optional = (key: string): unknown => value[key] || undefined;
      return firstValueFrom(
        this.api.post(API.repair, {
          room_id: String(value['room_id'] ?? ''),
          contact_phone: String(value['contact_phone'] ?? ''),
          owner_id: optional('owner_id'),
          category: optional('category'),
          urgency: optional('urgency'),
          scheduled_at: optional('scheduled_at'),
          description: optional('description'),
        }),
      );
    }
    const row = this.actionRow();
    if (!row) throw new Error('未选择报修单');
    const id = String(row['id']);
    if (this.actionMode() === 'assign') {
      return firstValueFrom(
        this.api.put(API.repairAssign(id), {
          // 后端收 hashid（2026-10-03 起），无效/不存在判 422
          staff_id: String(value['staff_id'] ?? ''),
          // 空备注省略该字段，保留后端默认文案
          remark: String(value['remark'] ?? '') || undefined,
        }),
      );
    }
    return firstValueFrom(
      this.api.post(API.repairProgress(id), {
        status: Number(value['status']),
        remark: String(value['remark'] ?? '') || undefined,
      }),
    );
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };
}
