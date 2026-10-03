// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 操作日志：只读列表（形状 B：page + limit），行操作弹详情看请求参数。
// user_id 过滤参数后端要的是数字 ID，而列表里只有 user_name，故不提供该筛选项。
import { Component, TemplateRef, inject, signal, viewChild } from '@angular/core';
import { NzDescriptionsModule } from 'ng-zorro-antd/descriptions';
import { NzModalService } from 'ng-zorro-antd/modal';

import { API, ApiService } from '../../api/api.service';
import { LOG_SOURCES } from '../../api/dict';
import { Query } from '../../api/types';
import { DataTableComponent } from '../../components/data-table/data-table';
import { Column, RowAction } from '../../components/types';

interface LogRow extends Record<string, unknown> {
  id: string;
  user_name: string;
  action: string;
  method: string;
  path: string;
  ip: string;
  source: string;
  input: string;
  created_at: string;
}

@Component({
  selector: 'xz-system-logs',
  imports: [DataTableComponent, NzDescriptionsModule],
  template: `
    <xz-data-table
      title="操作日志"
      [columns]="columns"
      [filters]="filters"
      [load]="loader"
      [rowActions]="rowActions"
    />

    <ng-template #detail>
      @if (current(); as row) {
        <nz-descriptions [nzColumn]="2" nzBordered nzSize="small">
          <nz-descriptions-item nzTitle="操作人">{{ row.user_name || '-' }}</nz-descriptions-item>
          <nz-descriptions-item nzTitle="方法">{{ row.method }}</nz-descriptions-item>
          <nz-descriptions-item nzTitle="动作">{{ row.action }}</nz-descriptions-item>
          <nz-descriptions-item nzTitle="IP">{{ row.ip || '-' }}</nz-descriptions-item>
          <nz-descriptions-item nzTitle="请求路径" [nzSpan]="2">
            <code>{{ row.path }}</code>
          </nz-descriptions-item>
          <nz-descriptions-item nzTitle="操作时间" [nzSpan]="2">
            {{ row.created_at }}
          </nz-descriptions-item>
          <nz-descriptions-item nzTitle="请求参数" [nzSpan]="2">
            <pre class="params">{{ pretty(row.input) }}</pre>
          </nz-descriptions-item>
        </nz-descriptions>
      }
    </ng-template>
  `,
  styles: [
    `
      .params {
        max-height: 280px;
        margin: 0;
        overflow: auto;
        font-size: 12px;
        white-space: pre-wrap;
        word-break: break-all;
      }
    `,
  ],
})
export class LogsComponent {
  private readonly api = inject(ApiService);
  private readonly modal = inject(NzModalService);
  private readonly detailTpl = viewChild.required<TemplateRef<void>>('detail');

  protected readonly current = signal<LogRow | null>(null);

  protected readonly columns: Column[] = [
    { key: 'user_name', title: '操作人', kind: 'strong', width: '130px' },
    { key: 'action', title: '动作', width: '180px' },
    // 属性值不是状态 → 纯文本（React 该列就是裸值：GET/POST/PUT/DELETE）
    { key: 'method', title: '方法', width: '90px' },
    // 表头措辞与筛选区、详情抽屉及 React 端一致（显式版，不用「路径 / 时间」简写）
    { key: 'path', title: '请求路径', width: '260px' },
    { key: 'ip', title: 'IP', width: '140px' },
    // 来源端：后端 8 个端自动检测（install.sql:560 八值枚举），裸标识（harmonyos）映射成展示名
    { key: 'source', title: '来源端', width: '110px', lookup: (v) => LOG_SOURCES[v] },
    { key: 'created_at', title: '操作时间', width: '160px', kind: 'datetime' },
  ];

  protected readonly filters = [
    { key: 'path', label: '请求路径', placeholder: '如 /admin/user' },
    { key: 'action', label: '动作', placeholder: '如 admin.user.store' },
    { key: 'start_date', label: '开始日期', kind: 'date' as const },
    { key: 'end_date', label: '结束日期', kind: 'date' as const },
  ];

  protected readonly rowActions: RowAction<LogRow>[] = [
    { label: '详情', run: (row) => this.showDetail(row) },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getManualPage<LogRow>(API.log, query, page, size);

  private showDetail(row: LogRow): void {
    this.current.set(row);
    this.modal.info({
      nzTitle: `${row.action} · ${row.method}`,
      nzWidth: 680,
      nzContent: this.detailTpl(),
    });
  }

  /** 请求参数是后端脱敏后的 JSON 字符串；解析失败原样显示 */
  protected pretty(raw: string): string {
    if (!raw) return '（无请求参数）';
    try {
      return JSON.stringify(JSON.parse(raw), null, 2);
    } catch {
      return raw;
    }
  }
}
