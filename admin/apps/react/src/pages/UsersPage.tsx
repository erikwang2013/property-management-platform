// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import type { AdminUserRow } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import PasswordPrompt from '../components/PasswordPrompt'
import { STATUS_MAPS, StatusTag, toOptions } from '../components/StatusTag'

// 列宽显式声明（规范 §1.3）：逐列对齐 Angular users.ts（含邮箱 180，两端同值；README「全站列宽」）。
const baseColumns: Column<AdminUserRow>[] = [
  { title: '用户名', key: 'username', width: 140 },
  { title: '姓名', key: 'real_name', width: 120 },
  { title: '手机号（脱敏）', key: 'phone', width: 140 },
  { title: '邮箱（脱敏）', key: 'email', width: 180 },
  { title: '状态', key: 'status', width: 90, render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.enable} /> },
  { title: '最近登录', key: 'last_login_at', width: 150 },
  { title: '创建时间', key: 'created_at', width: 150 },
]

const filters: Filter[] = [
  { name: 'keyword', label: '搜索用户名 / 姓名' },
  { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.enable) },
]

const commonFields: Field[] = [
  { name: 'real_name', label: '姓名', required: true },
  { name: 'phone', label: '手机号' },
  { name: 'email', label: '邮箱' },
  { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.enable) },
]

export default function UsersPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const [editing, setEditing] = useState<AdminUserRow | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [pending, setPending] = useState<AdminUserRow | null>(null)
  const [batchIds, setBatchIds] = useState<string[] | null>(null)

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['users'] })

  const fields: Field[] = editing
    ? [{ name: 'password', label: '新密码', type: 'password', extra: '留空表示不修改' }, ...commonFields]
    : [
        { name: 'username', label: '用户名', required: true },
        { name: 'password', label: '密码', type: 'password', required: true },
        ...commonFields,
      ]

  const save = async (values: Record<string, unknown>) => {
    if (editing) await api.put(item(EP.user, editing.id), values)
    else await api.post(EP.user, values)
    message.success(editing ? '更新成功' : '创建成功')
    await invalidate()
  }

  return (
    <>
      <ListPage<AdminUserRow>
        title="用户管理"
        endpoint={EP.user}
        shape="flat"
        queryKey="users"
        columns={baseColumns}
        filters={filters}
        selectable
        batchActions={(ids) => (
          <>
            <Button
              size="small"
              onClick={async () => {
                await api.post(EP.userBatchStatus, { ids, status: 1 })
                message.success('已批量启用')
                await invalidate()
              }}
            >
              批量启用
            </Button>
            <Button
              size="small"
              onClick={async () => {
                await api.post(EP.userBatchStatus, { ids, status: 0 })
                message.success('已批量禁用')
                await invalidate()
              }}
            >
              批量禁用
            </Button>
            <Button size="small" danger onClick={() => setBatchIds(ids)}>
              批量删除
            </Button>
          </>
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
          <Button
            type="primary"
            onClick={() => {
              setEditing(null)
              setModalOpen(true)
            }}
          >
            新建用户
          </Button>
        }
      />

      <FormModal
        open={modalOpen}
        title={editing ? `编辑用户 · ${editing.username}` : '新建用户'}
        fields={fields}
        initial={editing ? { ...editing, password: '' } : { status: 1 }}
        onClose={() => setModalOpen(false)}
        onSubmit={save}
      />

      <PasswordPrompt
        open={Boolean(pending)}
        title={`删除用户「${pending?.username ?? ''}」`}
        onCancel={() => setPending(null)}
        onOk={async (password) => {
          if (!pending) return
          await api.del(item(EP.user, pending.id), password)
          message.success('删除成功')
          await invalidate()
        }}
      />

      <PasswordPrompt
        open={Boolean(batchIds)}
        title={`批量删除 ${batchIds?.length ?? 0} 个用户`}
        onCancel={() => setBatchIds(null)}
        onOk={async (password) => {
          const data = await api.post<{ count: number }>(EP.userBatchDestroy, { ids: batchIds, password })
          message.success(`已删除 ${data.count} 个用户`)
          await invalidate()
        }}
      />
    </>
  )
}
