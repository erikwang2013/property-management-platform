// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button, Flex } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import type { Owner } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import PasswordPrompt from '../components/PasswordPrompt'
import { STATUS_MAPS, StatusTag, statusText, toOptions } from '../components/StatusTag'

// 列宽显式声明（规范 §1.3）：逐列对齐 Angular owners.ts（含邮箱 180，两端同值；README「全站列宽」）。
const columns: Column<Owner>[] = [
  { title: '姓名', key: 'name', width: 120 },
  { title: '手机号（脱敏）', key: 'phone', width: 140 },
  { title: '邮箱（脱敏）', key: 'email', width: 180 },
  { title: '性别', key: 'gender', width: 80, render: (row) => statusText(row.gender, STATUS_MAPS.gender) },
  { title: '入住日期', key: 'check_in_date', width: 110 },
  { title: '状态', key: 'status', width: 90, render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.owner} /> },
  { title: '创建时间', key: 'created_at', width: 150 },
]

const filters: Filter[] = [
  { name: 'keyword', label: '搜索姓名 / 手机号' },
  { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.owner) },
]

const fields: Field[] = [
  { name: 'name', label: '姓名', required: true },
  { name: 'phone', label: '手机号', required: true },
  { name: 'email', label: '邮箱' },
  { name: 'id_card', label: '身份证号', disabled: true, extra: '创建后不可修改' },
  { name: 'gender', label: '性别', type: 'select', options: toOptions(STATUS_MAPS.gender) },
  { name: 'birthday', label: '生日', type: 'date' },
  { name: 'check_in_date', label: '入住日期', type: 'date' },
  { name: 'emergency_contact', label: '紧急联系人' },
  { name: 'emergency_phone', label: '紧急联系电话' },
  { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.owner) },
  { name: 'remark', label: '备注', type: 'textarea' },
]

export default function OwnersPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const [editing, setEditing] = useState<Owner | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [pending, setPending] = useState<Owner | null>(null)
  const [batchIds, setBatchIds] = useState<string[] | null>(null)

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['owners'] })

  const save = async (values: Record<string, unknown>) => {
    if (editing) await api.put(item(EP.owner, editing.id), values)
    else await api.post(EP.owner, values)
    message.success(editing ? '更新成功' : '创建成功')
    await invalidate()
  }

  return (
    <>
      <ListPage<Owner>
        title="业主管理"
        endpoint={EP.owner}
        queryKey="owners"
        columns={columns}
        filters={filters}
        selectable
        batchActions={(ids) => (
          <Button danger size="small" onClick={() => setBatchIds(ids)}>
            批量删除
          </Button>
        )}
        rowActions={(row) => [
          <Button
            key="edit"
            type="link"
            size="small"
            onClick={() => {
              setEditing(row)
              setModalOpen(true)
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
            <Button
              type="primary"
              onClick={() => {
                setEditing(null)
                setModalOpen(true)
              }}
            >
              新建业主
            </Button>
          </Flex>
        }
      />

      <FormModal
        open={modalOpen}
        title={editing ? `编辑业主 · ${editing.name}` : '新建业主'}
        fields={editing ? fields.filter((f) => f.name !== 'id_card') : fields}
        initial={editing ? { ...editing } : undefined}
        onClose={() => setModalOpen(false)}
        onSubmit={save}
      />

      <PasswordPrompt
        open={Boolean(pending)}
        title={`删除业主「${pending?.name ?? ''}」`}
        onCancel={() => setPending(null)}
        onOk={async (password) => {
          if (!pending) return
          await api.del(item(EP.owner, pending.id), password)
          message.success('删除成功')
          await invalidate()
        }}
      />

      <PasswordPrompt
        open={Boolean(batchIds)}
        title={`批量删除 ${batchIds?.length ?? 0} 位业主`}
        onCancel={() => setBatchIds(null)}
        onOk={async (password) => {
          const data = await api.post<{ count: number }>(EP.ownerBatchDestroy, { ids: batchIds, password })
          message.success(`已删除 ${data.count} 位业主`)
          await invalidate()
        }}
      />
    </>
  )
}
