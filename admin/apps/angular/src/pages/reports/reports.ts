// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 报表中心：日期区间 + 小区筛选 → 汇总卡 + 多图 + 欠费 TOP10 + PDF 导出。
import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NzAlertModule } from 'ng-zorro-antd/alert';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzCardModule } from 'ng-zorro-antd/card';
import { NzDatePickerModule } from 'ng-zorro-antd/date-picker';
import { NzEmptyModule } from 'ng-zorro-antd/empty';
import { NzGridModule } from 'ng-zorro-antd/grid';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzSelectModule } from 'ng-zorro-antd/select';
import { NzSkeletonModule } from 'ng-zorro-antd/skeleton';
import { NzTableModule } from 'ng-zorro-antd/table';
import type { EChartsCoreOption } from 'echarts/core';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { COMPLAINT_STATUS, REPAIR_CATEGORY, REPAIR_STATUS, VISITOR_STATUS } from '../../api/dict';
import { Option, Query } from '../../api/types';
import { baseOption, categoryAxis, ChartComponent, valueAxis } from '../../components/chart/chart';
import { formatMoney } from '../../components/money';
import { TOKENS } from '../../theme/tokens';

interface Summary {
  total_billed: number;
  total_paid: number;
  arrears: number;
  collection_rate: number;
  total_rooms: number;
  occupied_rooms: number;
  occupancy_rate: number;
  pending_repairs: number;
  pending_complaints: number;
  visitors_today: number;
  parking_now: number;
}

interface TrendPoint {
  month: string;
  total: number;
}

interface PaymentMethod {
  name: string;
  count: number;
  total: number;
}

/** 后端按 status / category 分组计数，键名随分组字段而变 */
interface CountRow {
  status?: number;
  category?: string;
  count: number;
}

interface ArrearsRow extends Record<string, unknown> {
  owner_name: string;
  owner_phone: string;
  room_name: string;
  arrears: number;
}

interface ReportData {
  summary: Summary;
  income_trend: TrendPoint[];
  expense_trend: TrendPoint[];
  payment_methods: PaymentMethod[];
  repair_status: CountRow[];
  complaint_status: CountRow[];
  visitor_status: CountRow[];
  repair_category: CountRow[];
  arrears_ranking: ArrearsRow[];
}

interface CommunityRow {
  id: string;
  name: string;
}

/** `money: true` 的卡片值走 formatMoney，单位写在标签里（规范 §1.3：「应收合计（元）」） */
const STAT_CARDS: {
  key: keyof Summary;
  label: string;
  icon: string;
  color: string;
  unit?: string;
  money?: boolean;
}[] = [
  { key: 'total_billed', label: '应收合计（元）', icon: 'file-done', color: TOKENS.primary, money: true },
  { key: 'total_paid', label: '实收合计（元）', icon: 'account-book', color: TOKENS.success, money: true },
  { key: 'arrears', label: '欠费合计（元）', icon: 'warning', color: TOKENS.error, money: true },
  { key: 'collection_rate', label: '收缴率', icon: 'percentage', color: TOKENS.primaryLight, unit: '%' },
  { key: 'occupancy_rate', label: '入住率', icon: 'home', color: TOKENS.accent, unit: '%' },
  { key: 'pending_repairs', label: '待处理报修', icon: 'tool', color: TOKENS.warning, unit: '单' },
  { key: 'pending_complaints', label: '待处理投诉', icon: 'message', color: TOKENS.error, unit: '单' },
  { key: 'visitors_today', label: '今日访客', icon: 'team', color: TOKENS.primary, unit: '人' },
];

@Component({
  selector: 'xz-reports',
  imports: [
    FormsModule,
    ChartComponent,
    NzAlertModule,
    NzButtonModule,
    NzCardModule,
    NzDatePickerModule,
    NzEmptyModule,
    NzGridModule,
    NzIconModule,
    NzSelectModule,
    NzSkeletonModule,
    NzTableModule,
  ],
  templateUrl: './reports.html',
  styleUrl: './reports.scss',
})
export class ReportsComponent {
  private readonly api = inject(ApiService);
  private readonly message = inject(NzMessageService);

  protected readonly statCards = STAT_CARDS;
  /** 模板里也能直接用（TOP10 金额单元格） */
  protected readonly money = formatMoney;
  protected readonly loading = signal(false);
  protected readonly exporting = signal(false);
  /** 后端 ReportController 未注册路由时为 true，页面显示说明而不是空白 */
  protected readonly failed = signal('');

  protected readonly range = signal<[Date, Date]>([
    new Date(Date.now() - 29 * 86400000),
    new Date(),
  ]);
  protected readonly communityId = signal<string>('');
  protected communities = signal<Option[]>([]);

  protected readonly data = signal<ReportData | null>(null);

  /** 今天之后的日期不可选 */
  protected readonly disabledDate = (d: Date): boolean => d.getTime() > Date.now();

  constructor() {
    void this.loadCommunities();
    this.reload();
  }

  private async loadCommunities(): Promise<void> {
    try {
      const page = await firstValueFrom(
        this.api.getPage<CommunityRow>(API.community, {}, 1, 100),
      );
      this.communities.set(page.rows.map((c) => ({ label: c.name, value: c.id })));
    } catch {
      // 小区下拉只是筛选维度，取不到不影响报表主体
      this.communities.set([]);
    }
  }

  protected readonly query = computed<Query>(() => {
    const [start, end] = this.range();
    return {
      start_date: this.formatDate(start),
      end_date: this.formatDate(end),
      community_id: this.communityId(),
    };
  });

  protected reload(): void {
    this.loading.set(true);
    this.failed.set('');
    this.api.get<ReportData>(API.report, this.query()).subscribe({
      next: (res) => {
        this.data.set(res);
        this.loading.set(false);
      },
      error: (err: unknown) => {
        this.loading.set(false);
        this.data.set(null);
        this.failed.set(errorText(err));
      },
    });
  }

  protected onRangeChange(dates: [Date, Date] | null): void {
    if (!dates || dates.length !== 2 || !dates[0] || !dates[1]) return;
    this.range.set(dates);
  }

  /** 区间上限 366 天，避免一次渲染过密的横轴 */
  protected readonly rangeTooLong = computed(
    () => (this.range()[1].getTime() - this.range()[0].getTime()) / 86400000 > 366,
  );

  // —— 图表 option（页面只描述数据，基调由 baseOption() 统一；形状逐项对齐 React ReportsPage） ——

  /**
   * 状态分布饼图 —— 与 React 的 `pie()` 同形：环形 42%~68%、白描边、图例贴底可滚动。
   * 四张状态饼（缴费方式 / 报修 / 投诉 / 访客）共用，避免一页三种饼形。
   */
  private pie(rows: { name: string; value: number }[], name: string): EChartsCoreOption {
    return {
      ...baseOption(),
      tooltip: { trigger: 'item' },
      legend: { bottom: 0, top: undefined, type: 'scroll' },
      series: [
        {
          name,
          type: 'pie',
          radius: ['42%', '68%'],
          itemStyle: { borderColor: '#fff', borderWidth: 2 },
          data: rows,
        },
      ],
    };
  }

  protected readonly trendOption = computed(() => {
    const d = this.data();
    const income = d?.income_trend ?? [];
    const expense = d?.expense_trend ?? [];
    // 收入柱 + 支出线，主色/错误色（React 的 chartColors[0]/[3]）。
    // 唯一的加码：横轴取两串月份的**并集**再排序 —— React 只用收入月份，支出多出一月时那月会被丢掉。
    const months = [...new Set([...income.map((i) => i.month), ...expense.map((e) => e.month)])].sort();
    const pick = (rows: TrendPoint[]) =>
      months.map((m) => rows.find((r) => r.month === m)?.total ?? 0);

    return {
      ...baseOption(),
      color: [TOKENS.primary, TOKENS.error],
      tooltip: { trigger: 'axis' },
      legend: { bottom: 0, top: undefined },
      grid: { left: 56, right: 16, top: 24, bottom: 40 },
      xAxis: { ...categoryAxis(months), boundaryGap: true },
      yAxis: valueAxis(),
      series: [
        { name: '收入', type: 'bar', data: pick(income) },
        { name: '支出', type: 'line', smooth: true, data: pick(expense) },
      ],
    };
  });

  protected readonly paymentOption = computed(() =>
    this.pie(
      (this.data()?.payment_methods ?? []).map((p) => ({ name: p.name, value: p.total })),
      '支付方式',
    ),
  );

  protected readonly repairCategoryOption = computed(() => {
    const rows = this.data()?.repair_category ?? [];
    const labels = rows.map((r) => REPAIR_CATEGORY[Number(r.category)] ?? `分类 ${r.category}`);
    return {
      ...baseOption(),
      tooltip: { trigger: 'axis' },
      grid: { left: 56, right: 16, top: 24, bottom: 40 },
      xAxis: { ...categoryAxis(labels), boundaryGap: true },
      yAxis: valueAxis(),
      series: [{ name: '报修单', type: 'bar', data: rows.map((r) => r.count) }],
    };
  });

  protected readonly complaintOption = computed(() =>
    this.pie(
      (this.data()?.complaint_status ?? []).map((r) => ({
        name: COMPLAINT_STATUS[Number(r.status)] ?? `状态 ${r.status}`,
        value: r.count,
      })),
      '投诉状态',
    ),
  );

  protected readonly repairStatusOption = computed(() =>
    this.pie(
      (this.data()?.repair_status ?? []).map((r) => ({
        name: REPAIR_STATUS[Number(r.status)] ?? `状态 ${r.status}`,
        value: r.count,
      })),
      '报修状态',
    ),
  );

  /** 访客状态（React 该图图例是裸 `状态0..3`；本端按 install.sql:1010 映射成文案，已报 lead 让对端跟上） */
  protected readonly visitorOption = computed(() =>
    this.pie(
      (this.data()?.visitor_status ?? []).map((r) => ({
        name: VISITOR_STATUS[Number(r.status)] ?? `状态 ${r.status}`,
        value: r.count,
      })),
      '访客状态',
    ),
  );

  /** 欠费 TOP10 的四个数据列 —— 宽度全部显式声明（规格 §1.3 行 51），取值与 React 同值：
   *  不声明时 auto 布局会按内容撑成 188/286/299/272，两端各撑一套。 */
  protected readonly arrearsColumns = [
    { title: '业主', width: '120px' },
    { title: '联系电话', width: '140px' },
    { title: '房号', width: '160px' },
    { title: '欠费金额(元)', width: '120px' },
  ];

  /** 导出欠费 TOP10 —— 后端 PDF 导出只接受扁平表格 */
  protected async exportPdf(): Promise<void> {
    const rows = this.data()?.arrears_ranking ?? [];
    if (!rows.length) {
      this.message.warning('当前区间没有可导出的欠费数据');
      return;
    }
    this.exporting.set(true);
    try {
      const [start, end] = this.range();
      await firstValueFrom(
        this.api.download(
          API.exportPdf,
          {
            type: 'table',
            title: `欠费排行 ${this.formatDate(start)} ~ ${this.formatDate(end)}`,
            data: {
              columns: this.arrearsColumns.map((c) => c.title),
              rows: rows.map((r) => [r.owner_name, r.owner_phone, r.room_name, formatMoney(r.arrears)]),
            },
          },
          `arrears_${this.formatDate(start)}_${this.formatDate(end)}.pdf`,
        ),
      );
      this.message.success('导出已开始下载');
    } catch (err) {
      this.message.error(errorText(err));
    } finally {
      this.exporting.set(false);
    }
  }

  private formatDate(d: Date): string {
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  }
}
