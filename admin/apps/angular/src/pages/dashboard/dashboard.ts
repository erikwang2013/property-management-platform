// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzCardModule } from 'ng-zorro-antd/card';
import { NzEmptyModule } from 'ng-zorro-antd/empty';
import { NzGridModule } from 'ng-zorro-antd/grid';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzSkeletonModule } from 'ng-zorro-antd/skeleton';
import { NzTagModule } from 'ng-zorro-antd/tag';
import { NzTimelineModule } from 'ng-zorro-antd/timeline';
import type { EChartsCoreOption } from 'echarts/core';
import { forkJoin } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { AuthService } from '../../auth/auth.service';
import { ChartComponent, baseOption, categoryAxis, valueAxis } from '../../components/chart/chart';
import { TOKENS } from '../../theme/tokens';

interface StatItem {
  label: string;
  value: string;
  icon: string;
  color: string;
  trend?: number;
}

interface TrendSeries {
  name: string;
  data: number[];
  color: string;
}

interface DashboardData {
  stats: StatItem[];
  trends: { dates: string[]; series: TrendSeries[] };
  distribution: { user_status: { name: string; value: number }[] };
  recent_logs: LogRow[];
}

interface LogRow {
  id: string;
  action: string;
  method: string;
  path: string;
  ip: string;
  source: string;
  created_at: string;
  user_name: string;
}

interface Todo {
  label: string;
  path: string;
  value: number;
  color: string;
  icon: string;
}

/**
 * DashboardController 的统计卡 icon 是 Material 名（为 Flutter 版写的），
 * 直接丢给 <nz-icon> 会渲染空白。这里只映射名字，颜色仍用后端下发的值。
 * 词表与 React 版 DashboardPage.tsx 的 STAT_ICONS 逐键对齐（含 person_add → user-add），
 * 两端认不出的都走 appstore / AppstoreOutlined 兜底。
 */
const STAT_ICONS: Record<string, string> = {
  people: 'team',
  person_add: 'user-add',
  bolt: 'thunderbolt',
  description: 'file-text',
  home: 'home',
  money: 'wallet',
  warning: 'warning',
  build: 'tool',
};

function toStatIcon(icon: string): string {
  return STAT_ICONS[icon] ?? 'appstore';
}

@Component({
  selector: 'xz-dashboard',
  imports: [
    RouterLink,
    ChartComponent,
    NzButtonModule,
    NzCardModule,
    NzEmptyModule,
    NzGridModule,
    NzIconModule,
    NzSkeletonModule,
    NzTagModule,
    NzTimelineModule,
  ],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
})
export class DashboardComponent {
  private readonly api = inject(ApiService);
  private readonly message = inject(NzMessageService);
  protected readonly auth = inject(AuthService);
  /** 模板要用的 token 色值（时间线圆点）。timeline 的 nzColor 只认预设名或真实色值，
   *  预设名里只有色彩名（red/blue），页面内联色名/hex 违反规范 §1.3 line 53 —— 故引 token。 */
  protected readonly TOKENS = TOKENS;

  protected readonly loading = signal(true);
  protected readonly data = signal<DashboardData | null>(null);
  protected readonly todos = signal<Todo[]>([]);

  /** 按当前时段的问候（规格 §2 只有三档；此前多出的「夜深了(h<6)」未申报、已删 —— 要加得两侧一起动） */
  protected readonly greeting = computed(() => {
    const h = new Date().getHours();
    if (h < 12) return '早安';
    if (h < 18) return '午安';
    return '晚安';
  });

  protected readonly trendOption = computed<EChartsCoreOption>(() => {
    const t = this.data()?.trends;
    if (!t) return baseOption();
    return {
      ...baseOption(),
      xAxis: categoryAxis(t.dates),
      yAxis: valueAxis(),
      series: t.series.map((s) => ({
        name: s.name,
        type: 'line',
        smooth: true,
        showSymbol: false,
        lineStyle: { width: 2 },
        areaStyle: { opacity: 0.08 },
        itemStyle: { color: s.color },
        data: s.data,
      })),
    };
  });

  protected readonly pieOption = computed<EChartsCoreOption>(() => {
    const rows = this.data()?.distribution?.user_status ?? [];
    return {
      ...baseOption(),
      tooltip: { trigger: 'item' },
      legend: { bottom: 0, top: undefined, icon: 'circle' },
      series: [
        {
          type: 'pie',
          radius: ['52%', '74%'],
          center: ['50%', '44%'],
          avoidLabelOverlap: true,
          itemStyle: { borderColor: '#fff', borderWidth: 2 },
          label: { formatter: '{b} {c}' },
          data: rows.map((r, i) => ({
            name: r.name,
            value: r.value,
            itemStyle: { color: i === 0 ? TOKENS.primary : TOKENS.accent },
          })),
        },
      ],
    };
  });

  constructor() {
    this.load();
    this.loadTodos();
  }

  private load(): void {
    this.api.get<DashboardData>(API.dashboard).subscribe({
      next: (d) => {
        this.data.set({ ...d, stats: (d.stats ?? []).map((s) => ({ ...s, icon: toStatIcon(s.icon) })) });
        this.loading.set(false);
      },
      error: (err: unknown) => {
        this.loading.set(false);
        this.message.error(errorText(err));
      },
    });
  }

  /** 今日待办：直接读三个列表接口的 total，避免臆造后端没有的统计口径 */
  private loadTodos(): void {
    forkJoin({
      repairs: this.api.getPage<Record<string, unknown>>(API.repair, { status: 0 }, 1, 1),
      // 待处理投诉 = status 0（SQL 974 的编号；旧编号下写成 1 是「碰巧对」，编号归位后会变成处理中）
      complaints: this.api.getPage<Record<string, unknown>>(API.complaint, { status: 0 }, 1, 1),
      bills: this.api.getPage<Record<string, unknown>>(API.feeBill, { status: 3 }, 1, 1),
    }).subscribe({
      next: (r) => {
        this.todos.set([
          { label: '待派单报修', path: '/repairs', value: r.repairs.total, color: TOKENS.primary, icon: 'tool' },
          { label: '待处理投诉', path: '/complaints', value: r.complaints.total, color: TOKENS.accent, icon: 'message' },
          { label: '逾期账单', path: '/fee-bills', value: r.bills.total, color: TOKENS.error, icon: 'file-text' },
        ]);
      },
      // 待办取不到不阻塞值班台主体
      error: () => this.todos.set([]),
    });
  }

  protected sourceText(source: string): string {
    return source || 'web';
  }
}
