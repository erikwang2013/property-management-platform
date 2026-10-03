// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 通用列表页：搜索区 + 表格 + 分页 + 行操作。13 个模块共用，模块只描述列/筛选项/行操作。
import { Component, computed, effect, inject, input, model, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzDatePickerModule } from 'ng-zorro-antd/date-picker';
import { NzEmptyModule } from 'ng-zorro-antd/empty';
import { NzGridModule } from 'ng-zorro-antd/grid';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzInputModule } from 'ng-zorro-antd/input';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzSelectModule } from 'ng-zorro-antd/select';
import { NzTableModule } from 'ng-zorro-antd/table';
import { NzTagModule } from 'ng-zorro-antd/tag';

import { errorText } from '../../api/api.service';
import { Query } from '../../api/types';
import { DateValueCache } from '../date-value';
import { formatMoney } from '../money';
import { Column, FilterField, Loader, RowAction } from '../types';

@Component({
  selector: 'xz-data-table',
  imports: [
    FormsModule,
    NzButtonModule,
    NzDatePickerModule,
    NzEmptyModule,
    NzGridModule,
    NzIconModule,
    NzInputModule,
    NzSelectModule,
    NzTableModule,
    NzTagModule,
  ],
  templateUrl: './data-table.html',
  styleUrl: './data-table.scss',
})
export class DataTableComponent<T extends Record<string, unknown>> {
  private readonly message = inject(NzMessageService);

  readonly columns = input.required<Column[]>();
  readonly load = input.required<Loader<T>>();
  readonly filters = input<FilterField[]>([]);
  readonly rowActions = input<RowAction<T>[]>([]);
  readonly selectable = input(false);
  readonly rowKey = input('id');
  readonly title = input('');
  readonly emptyText = input('暂无数据');
  /** 外部改这个值即可触发重查（如弹窗保存后） */
  readonly refreshToken = input(0);

  /** 选中行的主键集合（批量操作用） */
  readonly selected = model<string[]>([]);

  protected readonly rows = signal<T[]>([]);
  protected readonly total = signal(0);
  protected readonly page = signal(1);
  protected readonly pageSize = signal(20);
  protected readonly loading = signal(false);
  protected readonly query = signal<Query>({});

  /** 搜索区草稿值，点「查询」才落到 query */
  protected readonly draft = signal<Query>({});
  protected readonly pageSizes = [10, 20, 50, 100];

  protected readonly allChecked = computed(
    () => this.rows().length > 0 && this.selected().length === this.rows().length,
  );
  protected readonly indeterminate = computed(
    () => this.selected().length > 0 && !this.allChecked(),
  );

  constructor() {
    effect(() => {
      // 依赖：数据源 / 页码 / 页长 / 查询条件 / 外部刷新信号
      this.load();
      this.query();
      this.page();
      this.pageSize();
      this.refreshToken();
      this.fetch();
    });
  }

  reload(): void {
    this.fetch();
  }

  private fetch(): void {
    this.loading.set(true);
    this.load()(this.query(), this.page(), this.pageSize()).subscribe({
      next: (res) => {
        this.rows.set(res.rows);
        this.total.set(res.total);
        this.loading.set(false);
        // 当前页被删空时回退一页
        if (res.rows.length === 0 && res.total > 0 && this.page() > 1) {
          this.page.update((p) => p - 1);
        }
      },
      error: (err: unknown) => {
        this.loading.set(false);
        this.rows.set([]);
        this.total.set(0);
        this.message.error(errorText(err));
      },
    });
  }

  protected search(): void {
    this.query.set({ ...this.draft() });
    this.page.set(1);
    this.selected.set([]);
  }

  protected reset(): void {
    this.draft.set({});
    this.search();
  }

  protected setDraft(key: string, value: unknown): void {
    this.draft.update((d) => ({ ...d, [key]: value as Query[string] }));
  }

  protected onPageIndexChange(index: number): void {
    this.page.set(index);
  }

  protected onPageSizeChange(size: number): void {
    this.pageSize.set(size);
    this.page.set(1);
  }

  protected toggleAll(checked: boolean): void {
    this.selected.set(checked ? this.rows().map((r) => this.idOf(r)) : []);
  }

  protected toggleRow(row: T, checked: boolean): void {
    const id = this.idOf(row);
    this.selected.update((ids) => (checked ? [...ids, id] : ids.filter((x) => x !== id)));
  }

  protected isChecked(row: T): boolean {
    return this.selected().includes(this.idOf(row));
  }

  protected idOf(row: T): string {
    return String(row[this.rowKey()] ?? '');
  }

  /** 行操作：跑完自动重查；run 抛错则弹提示且不重查 */
  protected async runAction(action: RowAction<T>, row: T): Promise<void> {
    try {
      await action.run(row);
    } catch (err) {
      this.message.error(errorText(err));
      return;
    }
    this.selected.set([]);
    this.fetch();
  }

  protected visibleActions(row: T): RowAction<T>[] {
    return this.rowActions().filter((a) => !a.hidden?.(row));
  }

  // —— 单元格渲染辅助 ——

  protected cellText(row: T, col: Column): string {
    // 组合列（如「费用周期」）自己拼整行，不套空值出口 —— 它的「—」由 render 内部逐段给
    if (col.render) return col.render(row) || '—';
    const value = row[col.key];
    const raw = value === null || value === undefined ? '' : String(value);
    // 关联列：查不到可读名时回落原值（与 React 侧 `roomName(id) || id` 同语义）。
    // 末尾的「—」是空值的统一出口（team-lead 2026-10-03 裁定：表格与详情抽屉的日期/描述/人员等
    // 所有空值一律「—」）。放在这里就不用给每个可空列各配一个 lookup —— 文本与日期单元格都经此。
    return col.lookup?.(raw) || raw || '—';
  }

  protected tagOf(row: T, col: Column) {
    const value = row[col.key] as string | number;
    return col.map?.[value] ?? { text: String(value ?? ''), color: 'default' };
  }

  /** 金额格式统一走 formatMoney（千分位 + 两位小数、值上不挂符号，规范 §1.3） */
  protected moneyOf(row: T, col: Column): string {
    return formatMoney(row[col.key] as number | string | null);
  }

  /** ISO8601 → 本地 `YYYY-MM-DD HH:mm`；后端已格式化的字符串原样透传 */
  protected datetimeOf(row: T, col: Column): string {
    const raw = this.cellText(row, col);
    if (!raw || !raw.includes('T')) return raw;
    const d = new Date(raw);
    if (Number.isNaN(d.getTime())) return raw;
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  /** 同 form-modal：必须走缓存，否则「筛选区日期一有值」就会触发无限重渲染（见 date-value.ts） */
  private readonly dateCache = new DateValueCache();

  protected dateQuery(key: string): Date | null {
    return this.dateCache.get(key, this.draft()[key]);
  }

  protected setDate(key: string, date: Date | null): void {
    this.setDraft(key, date ? this.formatDate(date) : '');
  }

  private formatDate(d: Date): string {
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  }
}
