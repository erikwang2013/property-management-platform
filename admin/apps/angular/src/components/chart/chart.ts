// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// ECharts 6 自封装：不引第三方 wrapper，只做 init / setOption / resize / dispose 四件事。
import { AfterViewInit, Component, ElementRef, OnDestroy, effect, input, viewChild } from '@angular/core';
import * as echarts from 'echarts/core';
import { BarChart, LineChart, PieChart } from 'echarts/charts';
import {
  GridComponent,
  LegendComponent,
  TitleComponent,
  TooltipComponent,
} from 'echarts/components';
import { CanvasRenderer } from 'echarts/renderers';
import type { EChartsCoreOption } from 'echarts/core';

import { CHART_PALETTE, TOKENS } from '../../theme/tokens';

echarts.use([
  LineChart,
  BarChart,
  PieChart,
  GridComponent,
  TooltipComponent,
  LegendComponent,
  TitleComponent,
  CanvasRenderer,
]);

/** 分类轴（折线/柱状共用） */
export function categoryAxis(data: string[]): Record<string, unknown> {
  return {
    type: 'category',
    boundaryGap: false,
    data,
    axisLine: { lineStyle: { color: TOKENS.border } },
    axisTick: { show: false },
    axisLabel: { color: TOKENS.textSecondary },
  };
}

/** 数值轴 */
export function valueAxis(): Record<string, unknown> {
  return {
    type: 'value',
    splitLine: { lineStyle: { color: TOKENS.border, type: 'dashed' } },
    axisLabel: { color: TOKENS.textSecondary },
  };
}

/** 统一图表基调（字体、网格线、提示框），避免各页面各写一份 */
export function baseOption(): EChartsCoreOption {
  return {
    color: [...CHART_PALETTE],
    textStyle: { fontFamily: TOKENS.text, color: TOKENS.textSecondary },
    grid: { left: 8, right: 16, top: 32, bottom: 8, containLabel: true },
    tooltip: { trigger: 'axis' },
    legend: { top: 0, icon: 'roundRect', itemWidth: 10, itemHeight: 10 },
    xAxis: categoryAxis([]),
    yAxis: valueAxis(),
  };
}

@Component({
  selector: 'xz-chart',
  template: `<div #host class="xz-chart" [style.height.px]="height()"></div>`,
  styles: `.xz-chart { width: 100%; }`,
})
export class ChartComponent implements AfterViewInit, OnDestroy {
  /** 完整 ECharts option；由页面用 baseOption() 扩展而来 */
  readonly option = input.required<EChartsCoreOption>();
  readonly height = input(300);

  private readonly host = viewChild.required<ElementRef<HTMLDivElement>>('host');
  private chart?: echarts.ECharts;
  private observer?: ResizeObserver;

  constructor() {
    // option 变化时重绘（页面用 signal 传值）
    effect(() => {
      const opt = this.option();
      this.chart?.setOption(opt, true);
    });
  }

  ngAfterViewInit(): void {
    this.chart = echarts.init(this.host().nativeElement);
    this.chart.setOption(this.option(), true);
    this.observer = new ResizeObserver(() => this.chart?.resize());
    this.observer.observe(this.host().nativeElement);
  }

  ngOnDestroy(): void {
    this.observer?.disconnect();
    this.chart?.dispose();
  }
}
