// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import dayjs from 'dayjs'
import { api } from '../api/client'
import { EP } from '../api/endpoints'
import type { FeePayment } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import RemoteSelect from '../components/RemoteSelect'
import { STATUS_MAPS, StatusTag, toOptions } from '../components/StatusTag'
import { formatMoney } from '../components/money'


// 列宽显式声明（规范 §1.3）：数值对齐 Angular fee-payments.ts。
// 原「账单」列已删（lead 2026-10-03，两端同删）：该列只能显示后端返回的裸 hashid（未反查账单编号），
// 读不出信息；反查要额外拉账单表且受分页限制，后端 join 又超出本轮范围，故取最省的删列。
const columns: Column<FeePayment>[] = [
  { title: '支付单号', key: 'payment_number', width: 190 },
  { title: '金额', key: 'amount', width: 120, align: 'right', render: (row) => <span className="mono">{formatMoney(row.amount)}</span> },
  { title: '支付方式', key: 'payment_method', width: 110, render: (row) => <StatusTag value={row.payment_method} list={STATUS_MAPS.paymentMethod} /> },
  { title: '渠道', key: 'payment_channel', width: 90, render: (row) => <StatusTag value={row.payment_channel} list={STATUS_MAPS.paymentChannel} /> },
  { title: '支付时间', key: 'paid_at', width: 150 },
  // 列集并集（lead 2026-10-03）：操作员ID 是 Angular 独有的列，宽度取 Angular fee-payments.ts 的 110。
  // 值是管理端数字 id（线上自助缴费为 0），与 Angular 一样原样显示，不做映射
  { title: '操作员ID', key: 'operator_id', width: 110 },
  { title: '备注', key: 'remark', width: 200 },
  { title: '创建时间', key: 'created_at', width: 150 },
]

const filters: Filter[] = [
  { name: 'keyword', label: '搜索支付单号' },
  { name: 'payment_method', label: '支付方式', type: 'select', options: toOptions(STATUS_MAPS.paymentMethod) },
  { name: 'payment_channel', label: '渠道', type: 'select', options: toOptions(STATUS_MAPS.paymentChannel) },
]

export default function FeePaymentsPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const [open, setOpen] = useState(false)

  const fields: Field[] = [
    {
      name: 'bill_id',
      label: '账单',
      type: 'custom',
      required: true,
      full: true,
      render: () => (
        <RemoteSelect
          endpoint={EP.feeBill}
          queryKey="payment-bill-search"
          toOption={(row) => ({
            label: `${String(row.bill_number)} · 应收 ${formatMoney(row.amount as number)} / 已缴 ${formatMoney(row.paid_amount as number)}`,
            value: String(row.id),
          })}
          placeholder="搜索账单编号"
        />
      ),
    },
    { name: 'amount', label: '收款金额', type: 'number', required: true },
    { name: 'payment_method', label: '支付方式', type: 'select', options: toOptions(STATUS_MAPS.paymentMethod) },
    { name: 'paid_at', label: '收款日期', type: 'date' },
    { name: 'receipt_url', label: '收据 URL' },
    { name: 'remark', label: '备注', type: 'textarea' },
  ]

  return (
    <>
      <ListPage<FeePayment>
        title="缴费记录"
        endpoint={EP.feePayment}
        queryKey="fee-payments"
        columns={columns}
        filters={filters}
        toolbar={
          <Button type="primary" onClick={() => setOpen(true)}>
            登记线下缴费
          </Button>
        }
      />

      <FormModal
        open={open}
        title="登记线下缴费"
        fields={fields}
        initial={{ payment_method: 3, paid_at: dayjs().format('YYYY-MM-DD') }}
        onClose={() => setOpen(false)}
        onSubmit={async (values) => {
          await api.post(EP.feePaymentOffline, values)
          message.success('收款成功，账单状态已同步更新')
          await queryClient.invalidateQueries({ queryKey: ['fee-payments'] })
          await queryClient.invalidateQueries({ queryKey: ['fee-bills'] })
        }}
        width={640}
      />
    </>
  )
}
