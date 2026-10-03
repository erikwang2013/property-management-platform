// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 投诉管理：详情（只读抽屉）+ 受理（0→1）+ 回访（1→3）。行操作可见性与后端守卫一一对应。
import { Component, computed, inject, signal } from '@angular/core';
import { NzDescriptionsModule } from 'ng-zorro-antd/descriptions';
import { NzDrawerModule } from 'ng-zorro-antd/drawer';
import { NzTagModule } from 'ng-zorro-antd/tag';
import { NzTimelineModule } from 'ng-zorro-antd/timeline';
import { firstValueFrom } from 'rxjs';

import { API, ApiService } from '../../api/api.service';
import {
  ANONYMOUS_TAGS,
  COMPLAINT_CATEGORY_TAGS,
  COMPLAINT_HANDLEABLE,
  COMPLAINT_STATUS,
  COMPLAINT_STATUS_TAGS,
  COMPLAINT_TYPE,
  COMPLAINT_TYPE_TAGS,
  COMPLAINT_VISITABLE,
  options,
} from '../../api/dict';
import { Query } from '../../api/types';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import {
  Column,
  FilterField,
  FormField,
  FormValue,
  RowAction,
} from '../../components/types';

interface ComplaintRow extends Record<string, unknown> {
  id: string;
  owner_id: string;
  room_id: string;
  type: number;
  category: number;
  title: string;
  status: number;
  is_anonymous: number;
  handler_id: string;
  handled_at: string;
  satisfaction: number;
  created_at: string;
}

/** GET /admin/complaint/{hashid}（字段以后端 show() 实际返回为准）。
 *  `images` 故意不声明、不渲染：`Complaint` 没有 json cast，该列是 **字符串或 null**，
 *  直接 `@for` 会逐字符渲染（React 侧同样不渲染它）。 */
interface ComplaintDetail {
  id: string;
  title: string;
  content: string;
  status: number;
  handler_remark: string;
  visitor_remark: string;
  satisfaction: number | null;
  handled_at: string;
  visitor_at: string;
  created_at: string;
}

@Component({
  selector: 'xz-complaints',
  imports: [
    DataTableComponent,
    FormModalComponent,
    NzDescriptionsModule,
    NzDrawerModule,
    NzTagModule,
    NzTimelineModule,
  ],
  templateUrl: './complaints.html',
})
export class ComplaintsComponent {
  private readonly api = inject(ApiService);

  protected readonly refresh = signal(0);

  // —— 详情抽屉（只读）：字段与 React 侧 Drawer 对齐，动作仍走下面那两个弹窗 ——
  protected readonly detailOpen = signal(false);
  protected readonly detail = signal<ComplaintDetail | null>(null);
  protected readonly statusTags = COMPLAINT_STATUS_TAGS;

  protected readonly openDetail = (row: ComplaintRow): void => {
    this.detail.set(null);
    this.detailOpen.set(true);
    this.api.get<ComplaintDetail>(API.complaintDetail(row.id)).subscribe({
      next: (data) => this.detail.set(data),
      error: () => this.detail.set(null),
    });
  };

  protected readonly statusText = (v: number): string => COMPLAINT_STATUS[v] ?? String(v);

  /** 时间线三条固定节点（与 React 同句）：提交 / 受理 / 回访 —— 没有的时间点不列 */
  protected readonly track = (d: ComplaintDetail): string[] => [
    `提交 · ${d.created_at}`,
    ...(d.handled_at ? [`受理 · ${d.handled_at}`] : []),
    ...(d.visitor_at ? [`回访 · ${d.visitor_at}`] : []),
  ];

  /** 受理 / 回访共用同一个表单弹窗 */
  protected readonly actionOpen = signal(false);
  protected readonly actionMode = signal<'handle' | 'visit'>('handle');
  protected readonly actionRow = signal<FormValue | null>(null);

  protected readonly columns: Column[] = [
    { key: 'title', title: '标题', kind: 'strong', width: '220px' },
    { key: 'type', title: '类型', kind: 'tag', map: COMPLAINT_TYPE_TAGS, width: '90px' },
    { key: 'category', title: '分类', kind: 'tag', map: COMPLAINT_CATEGORY_TAGS, width: '110px' },
    { key: 'status', title: '状态', kind: 'tag', map: COMPLAINT_STATUS_TAGS, width: '100px' },
    // 实名/匿名都挂标（取 dict 的 ANONYMOUS：0 实名 / 1 匿名）。
    // React 侧对实名渲染裸「—」，与本列不同 —— 已报 lead 裁定；「实名」不是空值，不套用「空值一律 —」那条。
    { key: 'is_anonymous', title: '匿名', kind: 'tag', map: ANONYMOUS_TAGS, width: '90px' },
    { key: 'handled_at', title: '受理时间', width: '150px' },
    // 满意度按 React 口径补的列（team-lead 2026-10-03 裁定：后端 index() 确实返回 satisfaction）
    { key: 'satisfaction', title: '满意度', width: '90px', align: 'right' },
    { key: 'created_at', title: '创建时间', width: '150px' },
  ];

  protected readonly filters: FilterField[] = [
    { key: 'type', label: '类型', kind: 'select', options: () => options(COMPLAINT_TYPE) },
    { key: 'status', label: '状态', kind: 'select', options: () => options(COMPLAINT_STATUS) },
  ];

  /** 后端读的是 handler_remark / visitor_remark，不是统一的 remark。
   *  两个说明都必填（React 侧同为 required）；措辞取 React 的「回访记录」（抽屉里同名字段）。 */
  protected readonly actionFields = computed<FormField[]>(() =>
    this.actionMode() === 'handle'
      ? [{ key: 'handler_remark', label: '受理说明', kind: 'textarea', required: true }]
      : [{ key: 'visitor_remark', label: '回访记录', kind: 'textarea', required: true }],
  );

  /** 标题带投诉标题（与 React 同格式），便于同时开多条时对上号 */
  protected readonly actionTitle = computed(() => {
    const base = this.actionMode() === 'handle' ? '受理投诉' : '回访投诉';
    const title = String(this.actionRow()?.['title'] ?? '');
    return title ? `${base} · ${title}` : base;
  });

  /** 可见性与 ComplaintController 的守卫一致（2026-10-03 后端改成 SQL 编号）：仅 0 可受理、仅 1 可回访。
   *  前端只管「显不显示」，真正准入仍由守卫判（不符会回 422）。 */
  protected readonly rowActions: RowAction<ComplaintRow>[] = [
    { label: '详情', run: (row) => this.openDetail(row) },
    {
      label: '受理',
      hidden: (row) => row.status !== COMPLAINT_HANDLEABLE,
      run: (row) => this.start('handle', row),
    },
    {
      label: '回访',
      hidden: (row) => row.status !== COMPLAINT_VISITABLE,
      run: (row) => this.start('visit', row),
    },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getPage<ComplaintRow>(API.complaint, query, page, size);

  private start(mode: 'handle' | 'visit', row: ComplaintRow): void {
    this.actionMode.set(mode);
    // values 只用于预填当前值，提交体在 submit 里按模式重建
    this.actionRow.set(row as unknown as FormValue);
    this.actionOpen.set(true);
  }

  protected readonly actionSubmit = async (value: FormValue): Promise<unknown> => {
    const row = this.actionRow();
    if (!row) throw new Error('未选择投诉');
    const id = String(row['id']);
    if (this.actionMode() === 'handle') {
      return firstValueFrom(
        this.api.put(API.complaintHandle(id), {
          handler_remark: String(value['handler_remark'] ?? ''),
        }),
      );
    }
    return firstValueFrom(
      this.api.post(API.complaintVisit(id), {
        visitor_remark: String(value['visitor_remark'] ?? ''),
      }),
    );
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };
}
