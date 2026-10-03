// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button, Flex } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import dayjs from 'dayjs'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import { useFeeTypes, useOwners, useRoomTree } from '../api/lookups'
import type { FeeBill } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import PasswordPrompt from '../components/PasswordPrompt'
import RemoteSelect from '../components/RemoteSelect'
import { STATUS_MAPS, StatusTag, toOptions } from '../components/StatusTag'
import { formatMoney } from '../components/money'


export default function FeeBillsPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const tree = useRoomTree()
  const feeTypes = useFeeTypes()
  const owners = useOwners()

  const [editing, setEditing] = useState<FeeBill | null>(null)
  const [editOpen, setEditOpen] = useState(false)
  const [createOpen, setCreateOpen] = useState(false)
  const [genOpen, setGenOpen] = useState(false)
  const [genCommunity, setGenCommunity] = useState<string | undefined>(undefined)
  const [pending, setPending] = useState<FeeBill | null>(null)

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['fee-bills'] })

  // 列宽显式声明（规范 §1.3）：数值对齐 Angular fee-bills.ts；列集取并集后两端一致（房产/费用类型原是 Angular 独有、费用周期原是本端独有，现已两端都有）。
  const columns: Column<FeeBill>[] = [
    { title: '账单编号', key: 'bill_number', width: 190 },
    { title: '房产', key: 'room_id', width: 150, render: (row) => tree.roomName(row.room_id) || row.room_id },
    { title: '费用类型', key: 'fee_type_id', width: 120, render: (row) => feeTypes.nameOf(row.fee_type_id) || row.fee_type_id },
    { title: '金额', key: 'amount', width: 120, align: 'right', render: (row) => <span className="mono">{formatMoney(row.amount)}</span> },
    { title: '已缴', key: 'paid_amount', width: 120, align: 'right', render: (row) => <span className="mono">{formatMoney(row.paid_amount)}</span> },
    // 「滞纳金」以 docs/install.sql:764 的列注释为准（late_fee COMMENT '滞纳金'）—— 本端曾写「违约金」，
    // Angular 已按 SQL 改名，此为两端统一口径；改文案前先看 SQL 的 COMMENT，别按业务直觉造词
    { title: '滞纳金', key: 'late_fee', width: 110, align: 'right', render: (row) => <span className="mono">{formatMoney(row.late_fee)}</span> },
    {
      // 起止合成一格（Angular fee-bills.ts 同句 `起 ~ 止`）：两列并排只是各占 120px 白位，信息完全重合
      title: '费用周期',
      key: 'start_date',
      width: 180,
      render: (row) => `${row.start_date || '—'} ~ ${row.end_date || '—'}`,
    },
    { title: '截止日期', key: 'due_date', width: 120 },
    { title: '状态', key: 'status', width: 100, render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.bill} /> },
    // 列集并集（lead 2026-10-03）：缴费时间是 Angular 独有的列，宽度取 Angular fee-bills.ts 的 150
    { title: '缴费时间', key: 'paid_at', width: 150 },
    { title: '创建时间', key: 'created_at', width: 150 },
  ]

  const filters: Filter[] = [
    { name: 'keyword', label: '搜索账单编号' },
    { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.bill) },
  ]

  const createFields: Field[] = [
    {
      name: 'room_id',
      label: '房产',
      type: 'custom',
      required: true,
      render: () => (
        <RemoteSelect
          endpoint={EP.room}
          queryKey="bill-room-search"
          toOption={(row) => ({ label: `${String(row.room_number)}（${tree.communityName.get(String(row.community_id)) ?? ''}）`, value: String(row.id) })}
          placeholder="搜索房号"
        />
      ),
    },
    { name: 'owner_id', label: '业主', type: 'select', options: owners.options },
    { name: 'fee_type_id', label: '费用类型', type: 'select', required: true, options: feeTypes.options },
    { name: 'amount', label: '账单金额', type: 'number', required: true },
    { name: 'start_date', label: '周期开始', type: 'date' },
    { name: 'end_date', label: '周期截止', type: 'date' },
    { name: 'due_date', label: '截止日期', type: 'date' },
    { name: 'remark', label: '备注', type: 'textarea' },
  ]

  const editFields: Field[] = [
    { name: 'amount', label: '账单金额', type: 'number' },
    { name: 'late_fee', label: '滞纳金', type: 'number' },
    { name: 'start_date', label: '周期开始', type: 'date' },
    { name: 'end_date', label: '周期截止', type: 'date' },
    { name: 'due_date', label: '截止日期', type: 'date' },
    { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.bill) },
    { name: 'remark', label: '备注', type: 'textarea' },
  ]

  const genFields: Field[] = [
    {
      name: 'community_id',
      label: '小区',
      type: 'select',
      required: true,
      options: [...tree.communityName].map(([value, label]) => ({ label, value })),
    },
    {
      name: 'building_id',
      label: '楼栋',
      type: 'select',
      required: true,
      options: genCommunity ? tree.buildingsOf.get(genCommunity) ?? [] : [],
    },
    { name: 'fee_type_id', label: '费用类型', type: 'select', required: true, options: feeTypes.options },
    { name: 'start_date', label: '周期开始', type: 'date', required: true },
    { name: 'end_date', label: '周期截止', type: 'date', required: true },
    { name: 'due_date', label: '截止日期', type: 'date' },
    {
      name: 'amount',
      label: '固定金额',
      type: 'number',
      extra: '留空则按费用类型单价 × 面积计算',
    },
  ]

  return (
    <>
      <ListPage<FeeBill>
        title="账单管理"
        endpoint={EP.feeBill}
        queryKey="fee-bills"
        columns={columns}
        filters={filters}
        rowActions={(row) => [
          <Button
            key="edit"
            type="link"
            size="small"
            onClick={() => {
              setEditing(row)
              setEditOpen(true)
            }}
          >
            编辑
          </Button>,
          <Button key="del" type="link" size="small" danger onClick={() => setPending(row)}>
            删除
          </Button>,
        ]}
        toolbar={
          <Flex gap={8}>
            <Button onClick={() => setCreateOpen(true)}>新建账单</Button>
            <Button type="primary" onClick={() => setGenOpen(true)}>
              批量生成
            </Button>
          </Flex>
        }
      />

      <FormModal
        open={createOpen}
        title="新建账单"
        fields={createFields}
        initial={{ start_date: dayjs().startOf('month').format('YYYY-MM-DD'), end_date: dayjs().endOf('month').format('YYYY-MM-DD') }}
        onClose={() => setCreateOpen(false)}
        onSubmit={async (values) => {
          await api.post(EP.feeBill, values)
          message.success('创建成功')
          await invalidate()
        }}
        width={720}
      />

      <FormModal
        open={editOpen}
        title={`编辑账单 · ${editing?.bill_number ?? ''}`}
        fields={editFields}
        initial={editing ? { ...editing } : undefined}
        onClose={() => setEditOpen(false)}
        onSubmit={async (values) => {
          if (!editing) return
          await api.put(item(EP.feeBill, editing.id), values)
          message.success('更新成功')
          await invalidate()
        }}
        width={640}
      />

      <FormModal
        open={genOpen}
        title="批量生成账单"
        fields={genFields}
        initial={{
          start_date: dayjs().startOf('month').format('YYYY-MM-DD'),
          end_date: dayjs().endOf('month').format('YYYY-MM-DD'),
        }}
        onClose={() => setGenOpen(false)}
        onValuesChange={(changed) => {
          if (changed.community_id !== undefined) setGenCommunity(changed.community_id as string)
        }}
        onSubmit={async (values) => {
          const data = await api.post<{ created: number; skipped: number }>(EP.feeBillBatchGenerate, values)
          message.success(`已生成 ${data.created} 条，跳过 ${data.skipped} 条（同期同类型已存在）`)
          await invalidate()
        }}
        width={720}
      />

      <PasswordPrompt
        open={Boolean(pending)}
        title={`删除账单「${pending?.bill_number ?? ''}」`}
        onCancel={() => setPending(null)}
        onOk={async (password) => {
          if (!pending) return
          await api.del(item(EP.feeBill, pending.id), password)
          message.success('删除成功')
          await invalidate()
        }}
      />
    </>
  )
}
