// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState, type ReactNode } from 'react'
import { Alert, Card, DatePicker, Flex, Input, Select, Space, Table, Typography } from 'antd'
import type { TableProps } from 'antd'
import type { Dayjs } from 'dayjs'
import { pageParams, useList, type PagingShape } from '../api/paging'
import { EmptyState } from './PetMark'

export interface Column<T> {
  title: string
  /** 行数据字段名；render 存在时以 render 为准 */
  key: string
  render?: (row: T) => ReactNode
  width?: number
  align?: 'left' | 'right' | 'center'
  /** 单行省略。表格是 auto 布局，只写 width 会被内容顶开，得靠这个标记给单元格上 `max-width:0`（见 index.css） */
  ellipsis?: boolean
}

export interface Filter {
  name: string
  label: string
  type?: 'text' | 'select' | 'dateRange'
  /** type='dateRange' 时结束日期的参数名 */
  endName?: string
  options?: { label: string; value: number | string }[]
  width?: number
}

export interface ListPageProps<T> {
  endpoint: string
  /** 后端分页形状：控制器手写分页（list/total）用 flat，Laravel 分页器用 paginator */
  shape?: PagingShape
  /** 查询缓存键前缀，同时用于 mutation 后 invalidate */
  queryKey: string
  columns: Column<T>[]
  filters?: Filter[]
  toolbar?: ReactNode | ((reload: () => void) => ReactNode)
  rowActions?: (row: T, reload: () => void) => ReactNode[]
  selectable?: boolean
  batchActions?: (ids: string[], clear: () => void) => ReactNode
  rowKey?: (row: T) => string
  extraParams?: Record<string, unknown>
  pageSize?: number
  title?: string
}

/**
 * 通用列表页：搜索区 + 表格 + 分页 + 行操作 + 多选批处理。
 * 13 个模块复用这一个组件，各自只描述列与筛选项。
 */
export default function ListPage<T>({
  endpoint,
  shape = 'paginator',
  queryKey,
  columns,
  filters = [],
  toolbar,
  rowActions,
  selectable,
  batchActions,
  rowKey = (row) => String((row as { id?: unknown }).id ?? ''),
  extraParams,
  pageSize: initialPageSize = 20,
  title,
}: ListPageProps<T>) {
  const [values, setValues] = useState<Record<string, unknown>>({})
  const [range, setRange] = useState<[Dayjs, Dayjs] | null>(null)
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(initialPageSize)
  const [selected, setSelected] = useState<string[]>([])

  const filterParams: Record<string, unknown> = { ...extraParams }
  for (const [k, v] of Object.entries(values)) {
    if (v !== undefined && v !== '' && v !== null) filterParams[k] = v
  }
  const rangeFilter = filters.find((f) => f.type === 'dateRange')
  if (rangeFilter && range) {
    filterParams[rangeFilter.name] = range[0].format('YYYY-MM-DD')
    if (rangeFilter.endName) filterParams[rangeFilter.endName] = range[1].format('YYYY-MM-DD')
  }

  const { data, isFetching, error, refetch } = useList<T>(
    [queryKey],
    endpoint,
    pageParams(shape, page, pageSize, filterParams),
    shape,
  )

  const rows = data?.rows ?? []
  const reload = () => {
    setSelected([])
    void refetch()
  }

  const tableColumns: TableProps<T>['columns'] = columns.map((col) => ({
    title: col.title,
    key: col.key,
    width: col.width,
    align: col.align,
    // 省略列同时把全文挂到 title（原生悬浮看全文），与 Angular data-table 的 `[attr.title]` 同一做法
    onCell: col.ellipsis
      ? (row: T) => ({
          className: 'cell-ellipsis',
          title: String((row as Record<string, unknown>)[col.key] ?? ''),
        })
      : undefined,
    // 自定义 render 的空值也要吃「—」这条口径（此前只覆盖了默认取字段的列）：
    // `nameOf(id) || id` 这类回退在 id 为空串时返回空串，单元格就白了，而 Angular 显示「—」。
    // 注意不能直接把自定义 render 的结果喂给 renderCell —— 它末尾是 String(value)，
    // 传进去一个 React 元素会变成 "[object Object]"；这里只对 null/undefined/'' 兜底，元素原样返回。
    render: (_: unknown, row: T) => {
      const content = col.render
        ? col.render(row)
        : renderCell((row as Record<string, unknown>)[col.key])
      return content === null || content === undefined || content === '' ? '—' : content
    },
  }))

  if (rowActions) {
    tableColumns.push({
      title: '操作',
      key: '__actions',
      // 170 与 Angular data-table.scss 的 .ops-head 同值（规范 §1.3：操作列含 3 个行内按钮，实测内容宽 React 156 / Angular 165，
      // 声明 170 后两端都恰好等于声明值、不随内容抖动）。auto 布局下声明宽是下限，写 150 会被 3 个按钮撑到 156。
      width: 170,
      align: 'left' as const,
      fixed: 'right' as const, // 横向溢出时行操作不随内容滚出视野（规范 §1.3，与 Angular 的 sticky right 等价）
      render: (_: unknown, row: T) => <Space size={4}>{rowActions(row, reload)}</Space>,
    })
  }

  return (
    <Flex vertical gap={16}>
      {title && <Typography.Title level={4} style={{ margin: 0 }}>{title}</Typography.Title>}
      <Card styles={{ body: { padding: 16 } }}>
        <Flex wrap gap={12} justify="space-between" align="center" style={{ marginBottom: 16 }}>
          <Space wrap size={12}>
            {filters.map((f) =>
              f.type === 'dateRange' ? (
                <DatePicker.RangePicker
                  key={f.name}
                  placeholder={['开始日期', '结束日期']}
                  value={range}
                  onChange={(v) => {
                    setRange(v as [Dayjs, Dayjs] | null)
                    setPage(1)
                  }}
                />
              ) : f.type === 'select' ? (
                <Select
                  key={f.name}
                  allowClear
                  placeholder={f.label}
                  style={{ width: f.width ?? 160 }}
                  options={f.options}
                  value={values[f.name] as number | string | undefined}
                  onChange={(v) => {
                    setValues((s) => ({ ...s, [f.name]: v }))
                    setPage(1)
                  }}
                />
              ) : (
                <Input.Search
                  key={f.name}
                  allowClear
                  placeholder={f.label}
                  style={{ width: f.width ?? 220 }}
                  onSearch={(v) => {
                    setValues((s) => ({ ...s, [f.name]: v }))
                    setPage(1)
                  }}
                />
              ),
            )}
          </Space>
          <Space wrap>{typeof toolbar === 'function' ? toolbar(reload) : toolbar}</Space>
        </Flex>

        {error && <Alert type="error" showIcon title={error.message} style={{ marginBottom: 12 }} />}

        {selectable && selected.length > 0 && batchActions && (
          <Flex align="center" gap={12} style={{ marginBottom: 12 }}>
            <Typography.Text type="secondary">已选 {selected.length} 项</Typography.Text>
            {batchActions(selected, () => setSelected([]))}
          </Flex>
        )}

        <Table<T>
          rowKey={rowKey}
          size="middle"
          columns={tableColumns}
          dataSource={rows}
          loading={isFetching}
          scroll={{ x: 'max-content' }}
          locale={{ emptyText: <EmptyState /> }}
          rowSelection={
            selectable
              ? {
                  selectedRowKeys: selected,
                  onChange: (keys) => setSelected(keys.map(String)),
                }
              : undefined
          }
          pagination={{
            current: page,
            pageSize,
            total: data?.total ?? 0,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 条`,
            onChange: (nextPage, nextSize) => {
              setPage(nextSize === pageSize ? nextPage : 1)
              setPageSize(nextSize)
            },
          }}
        />
      </Card>
    </Flex>
  )
}

function renderCell(value: unknown): ReactNode {
  // 空值符两端统一为全角破折号 —（Angular 表格/抽屉同此口径）
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'boolean') return value ? '是' : '否'
  return String(value)
}
