// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import type { ComponentType, CSSProperties } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Card, Col, Flex, Row, Statistic, Tag, Timeline, Typography } from 'antd'
import {
  AppstoreOutlined,
  FileTextOutlined,
  HomeOutlined,
  TeamOutlined,
  ThunderboltOutlined,
  ToolOutlined,
  UserAddOutlined,
  WalletOutlined,
  WarningOutlined,
} from '@ant-design/icons'
import { api } from '../api/client'
import { EP } from '../api/endpoints'
import { readPage } from '../api/paging'
import type { DashboardData, LogRow, StatCard } from '../api/types'
import { useAuth } from '../auth/store'
import Chart from '../components/Chart'
import { PetMark, petGreeting } from '../components/PetMark'
import { chartColors, colors } from '../theme/tokens'

/**
 * 后端 stats[].icon 是当年给 Flutter 版写的 Material 词表，认不出的走 Appstore 兜底。
 * 只映射名字：颜色一律用后端下发的 color（与 Angular 版同一份 payload 同一套呈现）。
 */
const STAT_ICONS: Record<string, ComponentType<{ style?: CSSProperties }>> = {
  people: TeamOutlined,
  person_add: UserAddOutlined,
  bolt: ThunderboltOutlined,
  description: FileTextOutlined,
  home: HomeOutlined,
  money: WalletOutlined,
  warning: WarningOutlined,
  build: ToolOutlined,
}

const countOf = async (path: string, params: Record<string, unknown>): Promise<number> =>
  readPage<unknown>(await api.get<unknown>(path, { page_size: 1, ...params })).total

export default function DashboardPage() {
  const navigate = useNavigate()
  const user = useAuth((s) => s.user)

  const dashboard = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => api.get<DashboardData>(EP.dashboard),
  })

  const todos = useQuery({
    queryKey: ['dashboard', 'todos'],
    queryFn: async () => ({
      repairs: await countOf(EP.repair, { status: 0 }),
      // 待处理投诉 = 0（install.sql:974 的编号；2026-10-03 后端改守卫后 1 的含义变为「处理中」，
      // 这个待办计数要跟着改，否则把处理中的单子算成待处理）
      complaints: await countOf(EP.complaint, { status: 0 }),
      overdueBills: await countOf(EP.feeBill, { status: 3 }),
    }),
  })

  const data = dashboard.data
  const trends = {
    dates: data?.trends?.dates ?? [],
    series: data?.trends?.series ?? [],
  }
  const distribution = data?.distribution?.user_status ?? []
  const logs: LogRow[] = data?.recent_logs ?? []

  const lineOption = {
    color: chartColors,
    tooltip: { trigger: 'axis' as const },
    legend: { bottom: 0 },
    grid: { left: 48, right: 16, top: 24, bottom: 40 },
    xAxis: { type: 'category' as const, data: trends.dates, boundaryGap: false },
    yAxis: { type: 'value' as const },
    series: trends.series.map((s) => ({
      name: s.name,
      type: 'line' as const,
      smooth: true,
      showSymbol: false,
      areaStyle: { opacity: 0.08 },
      data: s.data,
    })),
  }

  const pieOption = {
    color: chartColors,
    tooltip: { trigger: 'item' as const },
    legend: { bottom: 0 },
    series: [
      {
        type: 'pie' as const,
        radius: ['45%', '70%'],
        itemStyle: { borderColor: '#fff', borderWidth: 2 },
        data: distribution.map((d) => ({ name: d.name, value: d.value })),
      },
    ],
  }

  const todoItems = [
    { key: 'repairs', label: '待处理报修', value: todos.data?.repairs ?? 0, path: '/repairs' },
    { key: 'complaints', label: '待处理投诉', value: todos.data?.complaints ?? 0, path: '/complaints' },
    { key: 'bills', label: '逾期账单', value: todos.data?.overdueBills ?? 0, path: '/fee-bills' },
  ]

  return (
    <Flex vertical gap={16}>
      <Card styles={{ body: { padding: 20 } }}>
        <Flex align="center" gap={16} wrap>
          <PetMark size={48} />
          <Flex vertical>
            <Typography.Title level={4} style={{ margin: 0 }}>
              {petGreeting()}，{user?.real_name || user?.username || '管理员'}
            </Typography.Title>
            <Typography.Text type="secondary">
              今天有 {todoItems.reduce((sum, t) => sum + t.value, 0)} 项待办，先从最急的开始吧。
            </Typography.Text>
          </Flex>
          <Flex gap={12} wrap style={{ marginLeft: 'auto' }}>
            {todoItems.map((todo) => (
              <Card
                key={todo.key}
                size="small"
                hoverable
                onClick={() => navigate(todo.path)}
                style={{ minWidth: 140, cursor: 'pointer' }}
              >
                <Statistic
                  title={todo.label}
                  value={todo.value}
                  styles={{ content: { fontVariantNumeric: 'tabular-nums', color: colors.primary } }}
                />
              </Card>
            ))}
          </Flex>
        </Flex>
      </Card>

      <Row gutter={[16, 16]}>
        {(data?.stats ?? []).map((stat: StatCard) => {
          const Icon = STAT_ICONS[stat.icon ?? ''] ?? AppstoreOutlined
          const tint = stat.color ?? colors.primary
          return (
            <Col key={stat.label} xs={24} sm={12} lg={6}>
              <Card loading={dashboard.isFetching} styles={{ body: { padding: 16 } }}>
                <Flex align="center" gap={14}>
                  <Flex
                    align="center"
                    justify="center"
                    style={{
                      flex: '0 0 44px',
                      width: 44,
                      height: 44,
                      borderRadius: 8,
                      fontSize: 20,
                      background: `${tint}1A`,
                      color: tint,
                    }}
                  >
                    <Icon />
                  </Flex>
                  <Flex vertical style={{ flex: 1, minWidth: 0 }}>
                    <Typography.Text type="secondary" style={{ fontSize: 13 }}>
                      {stat.label}
                    </Typography.Text>
                    <span className="tabular" style={{ fontSize: 26, fontWeight: 700, lineHeight: 1.2 }}>
                      {stat.value}
                    </span>
                  </Flex>
                  {stat.trend === null || stat.trend === undefined ? null : (
                    <Tag color={stat.trend >= 0 ? 'success' : 'error'} style={{ marginInlineEnd: 0 }}>
                      {stat.trend >= 0 ? '+' : ''}
                      {stat.trend}%
                    </Tag>
                  )}
                </Flex>
              </Card>
            </Col>
          )
        })}
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={16}>
          <Card title="近 30 天趋势" loading={dashboard.isFetching}>
            <Chart option={lineOption} height={320} />
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title="用户状态分布" loading={dashboard.isFetching}>
            <Chart option={pieOption} height={320} />
          </Card>
        </Col>
      </Row>

      <Card title="最近操作" loading={dashboard.isFetching}>
        <Timeline
          items={logs.map((log) => ({
            content: (
              <Flex vertical>
                <Typography.Text>
                  {log.user_name} · {log.action}
                </Typography.Text>
                <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                  {log.method} {log.path} · {log.ip} · {log.created_at}
                </Typography.Text>
              </Flex>
            ),
          }))}
        />
      </Card>
    </Flex>
  )
}
