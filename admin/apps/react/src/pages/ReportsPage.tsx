// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button, Card, Col, DatePicker, Flex, Row, Select, Statistic, Table } from 'antd'
import { DownloadOutlined } from '@ant-design/icons'
import { useQuery } from '@tanstack/react-query'
import dayjs, { type Dayjs } from 'dayjs'
import { api, saveBlob } from '../api/client'
import { EP } from '../api/endpoints'
import { useCommunities } from '../api/lookups'
import type { ReportData } from '../api/types'
import Chart from '../components/Chart'
import { STATUS_MAPS, statusText } from '../components/StatusTag'
import { formatMoney } from '../components/money'
import { chartColors, colors } from '../theme/tokens'


// 系列名进 tooltip 标题（规范 §1.3：饼图 tooltip 带系列名，如「支付方式」）—— 两端同文案
const pie = (rows: { name: string; value: number }[], name: string) => ({
  color: chartColors,
  tooltip: { trigger: 'item' as const },
  legend: { bottom: 0, type: 'scroll' as const },
  series: [
    {
      name,
      type: 'pie' as const,
      radius: ['42%', '68%'],
      itemStyle: { borderColor: '#fff', borderWidth: 2 },
      data: rows,
    },
  ],
})

export default function ReportsPage() {
  const { message } = App.useApp()
  const communities = useCommunities()
  const [range, setRange] = useState<[Dayjs, Dayjs]>([dayjs().subtract(29, 'day'), dayjs()])
  const [communityId, setCommunityId] = useState<string | undefined>(undefined)

  const params = {
    start_date: range[0].format('YYYY-MM-DD'),
    end_date: range[1].format('YYYY-MM-DD'),
    community_id: communityId,
  }

  const report = useQuery({
    queryKey: ['report', params],
    queryFn: () => api.get<ReportData>(EP.report, params),
  })

  const data = report.data
  const summary = data?.summary

  // 横轴取两串月份的并集再排序（Angular reports.ts 同做法）。原先只取收入月份，而类目轴与系列是按下标对齐的：
  // 支出比收入多出某个月时，多出来的那个月会因轴上没有这个类目而丢点 —— 图照样能画、肉眼看着正常，
  // 只有真数据（两串月份不等长）才现形，桩数据抓不到。缺月按 0 补（后端聚合不返回计数为 0 的月份）。
  const income = data?.income_trend ?? []
  const expense = data?.expense_trend ?? []
  const months = [...new Set([...income.map((i) => i.month), ...expense.map((e) => e.month)])].sort()
  const trendOption = {
    // 显式取语义色而不是 `chartColors[下标]`：色序由 §1.3 管，一旦调整，按下标取的系列会**悄悄换色**
    // （收入保住主色、支出从玫红变成绿，看着还挺正常）。Angular 同处也是显式 TOKENS.primary / TOKENS.error
    color: [colors.primary, colors.error],
    tooltip: { trigger: 'axis' as const },
    legend: { bottom: 0 },
    grid: { left: 56, right: 16, top: 24, bottom: 40 },
    xAxis: { type: 'category' as const, data: months },
    yAxis: { type: 'value' as const },
    series: [
      { name: '收入', type: 'bar' as const, data: months.map((m) => income.find((i) => i.month === m)?.total ?? 0) },
      { name: '支出', type: 'line' as const, smooth: true, data: months.map((m) => expense.find((e) => e.month === m)?.total ?? 0) },
    ],
  }

  const ranking = data?.arrears_ranking ?? []

  const exportPdf = async () => {
    try {
      const blob = await api.request<Blob>(EP.exportPdf, {
        method: 'POST',
        blob: true,
        body: {
          type: 'table',
          title: `欠费排行 ${params.start_date} ~ ${params.end_date}`,
          data: {
            // 与表格表头、Angular `arrearsColumns` 同文案（导出是扁平表格，无排名列）
            columns: ['业主', '联系电话', '房号', '欠费金额(元)'],
            rows: ranking.map((r) => [r.owner_name, r.owner_phone, r.room_name, formatMoney(r.arrears)]),
          },
        },
      })
      saveBlob(blob, `report_${params.start_date}_${params.end_date}.pdf`)
      message.success('已导出 PDF')
    } catch (err) {
      message.error(err instanceof Error ? err.message : '导出失败')
    }
  }

  return (
    <Flex vertical gap={16}>
      <Card styles={{ body: { padding: 16 } }}>
        <Flex wrap gap={12} justify="space-between" align="center">
          <Flex wrap gap={12}>
            <DatePicker.RangePicker value={range} onChange={(v) => v && setRange(v as [Dayjs, Dayjs])} allowClear={false} />
            <Select
              allowClear
              placeholder="全部小区"
              style={{ width: 200 }}
              options={communities.options}
              value={communityId}
              onChange={setCommunityId}
            />
          </Flex>
          <Button icon={<DownloadOutlined />} onClick={() => void exportPdf()} disabled={!ranking.length}>
            导出 PDF
          </Button>
        </Flex>
      </Card>

      <Row gutter={[16, 16]}>
        {[
          { label: '应收合计（元）', value: formatMoney(summary?.total_billed) },
          { label: '实收合计（元）', value: formatMoney(summary?.total_paid) },
          { label: '欠费合计（元）', value: formatMoney(summary?.arrears) },
          { label: '收缴率', value: `${summary?.collection_rate ?? 0}%` },
          { label: '入住率', value: `${summary?.occupancy_rate ?? 0}%` },
          { label: '待处理报修', value: summary?.pending_repairs ?? 0 },
          { label: '待处理投诉', value: summary?.pending_complaints ?? 0 },
          { label: '今日访客', value: summary?.visitors_today ?? 0 },
        ].map((item) => (
          <Col key={item.label} xs={12} md={8} lg={6} xl={3}>
            <Card size="small" loading={report.isFetching}>
              <Statistic title={item.label} value={item.value} styles={{ content: { fontVariantNumeric: 'tabular-nums' } }} />
            </Card>
          </Col>
        ))}
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={14}>
          <Card title="收支趋势" loading={report.isFetching}>
            <Chart option={trendOption} height={320} />
          </Card>
        </Col>
        <Col xs={24} lg={10}>
          <Card title="支付方式分布" loading={report.isFetching}>
            <Chart option={pie((data?.payment_methods ?? []).map((p) => ({ name: p.name, value: p.total })), '支付方式')} height={320} />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={8}>
          <Card title="报修状态" loading={report.isFetching}>
            <Chart
              option={pie((data?.repair_status ?? []).map((r) => ({ name: statusText(r.status, STATUS_MAPS.repair), value: r.count })), '报修状态')}
              height={280}
            />
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title="投诉状态" loading={report.isFetching}>
            <Chart
              option={pie((data?.complaint_status ?? []).map((r) => ({ name: statusText(r.status, STATUS_MAPS.complaint), value: r.count })), '投诉状态')}
              height={280}
            />
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title="访客状态" loading={report.isFetching}>
            <Chart
              // 图例要映射成文案，别把枚举号甩给用户（原为 `状态${r.status}` → 「状态0/状态1」）；
              // 字典外的值兜底成「状态 N」而不是裸数字或 —（至少保住「这是状态字段」这点信息，同 Angular 的 ?? `状态 ${...}`）
              option={pie(
                (data?.visitor_status ?? []).map((r) => ({
                  name: STATUS_MAPS.visitor.find((o) => o.value === r.status)?.label ?? `状态 ${r.status}`,
                  value: r.count,
                })),
                '访客状态',
              )}
              height={280}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="报修分类" loading={report.isFetching}>
            <Chart
              option={{
                color: chartColors,
                tooltip: { trigger: 'axis' as const },
                grid: { left: 56, right: 16, top: 24, bottom: 40 },
                xAxis: {
                  type: 'category' as const,
                  data: (data?.repair_category ?? []).map((r) => statusText(r.category, STATUS_MAPS.repairCategory)),
                },
                yAxis: { type: 'value' as const },
                series: [{ name: '报修单', type: 'bar' as const, data: (data?.repair_category ?? []).map((r) => r.count) }],
              }}
              height={280}
            />
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="欠费排行 TOP10" loading={report.isFetching}>
            <Table
              size="small"
              rowKey={(row) => `${row.room_name}-${row.owner_name}`}
              dataSource={ranking}
              pagination={false}
              scroll={{ y: 220 }}
              columns={[
                // 列集/列名与 Angular reports.html 的欠费排行表逐字对齐（排名列 Angular 声明 60px）；
                // 后四列的声明宽是本端定值，Angular 该表尚未显式声明 —— 已报 lead 让其补齐同值
                { title: '排名', key: 'rank', width: 60, render: (_v, _r, i) => i + 1 },
                { title: '业主', dataIndex: 'owner_name', width: 120 },
                { title: '联系电话', dataIndex: 'owner_phone', width: 140 },
                { title: '房号', dataIndex: 'room_name', width: 160 },
                {
                  title: '欠费金额(元)',
                  dataIndex: 'arrears',
                  width: 120,
                  align: 'right',
                  // 表头已写「(元)」，值上不再挂 ¥（单位重复，窄列里还白占一个字符）——
                  // lead 2026-10-03 口径，Angular 同列也已去掉符号，别再单边加回来
                  render: (value: number) => <span className="mono">{formatMoney(value)}</span>,
                },
              ]}
            />
          </Card>
        </Col>
      </Row>
    </Flex>
  )
}
