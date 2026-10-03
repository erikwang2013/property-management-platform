// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { Alert, App, Button } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import dayjs from 'dayjs'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import { usePermissions } from '../api/lookups'
import type { Role } from '../api/types'
import ListPage, { type Column } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import PasswordPrompt from '../components/PasswordPrompt'
import { STATUS_MAPS, StatusTag, toOptions } from '../components/StatusTag'

// 列宽显式声明（规范 §1.3）：逐列对齐 Angular roles.ts（含描述 200，两端同值；README「全站列宽」）。
const columns: Column<Role>[] = [
  { title: '角色名', key: 'name', width: 160 },
  { title: '标识', key: 'slug', width: 180 },
  { title: '描述', key: 'description', width: 200 },
  { title: '用户数', key: 'users_count', width: 110, align: 'right' },
  { title: '状态', key: 'status', width: 100, render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.enable} /> },
  // 后端此处走 toArray()，created_at 是带 T 的 ISO8601；格式化到分钟与 Angular roles.ts 的 kind:'datetime' 同输出
  {
    title: '创建时间',
    key: 'created_at',
    width: 150,
    render: (row) => (row.created_at?.includes('T') ? dayjs(row.created_at).format('YYYY-MM-DD HH:mm') : row.created_at),
  },
]

export default function RolesPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const permissions = usePermissions()
  const [editing, setEditing] = useState<Role | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [pending, setPending] = useState<Role | null>(null)

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['roles'] })

  const fields: Field[] = [
    { name: 'name', label: '角色名', required: true },
    { name: 'slug', label: '标识 (slug)', required: true, disabled: Boolean(editing) },
    { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.enable) },
    { name: 'description', label: '描述', type: 'textarea' },
    {
      name: 'permission_ids',
      label: '权限',
      type: 'treeSelect',
      treeCheckable: true,
      full: true,
      treeData: permissions.treeData,
      extra: '角色接口不回传已勾选权限，保存会整体覆盖该角色的权限集合',
    },
  ]

  const save = async (values: Record<string, unknown>) => {
    const payload = { ...values, permission_ids: values.permission_ids ?? [] }
    if (editing) await api.put(item(EP.role, editing.id), payload)
    else await api.post(EP.role, payload)
    message.success(editing ? '更新成功' : '创建成功')
    await invalidate()
  }

  return (
    <>
      {permissions.error && <Alert type="warning" showIcon title="权限树加载失败，保存角色时请勿勾选权限" style={{ marginBottom: 12 }} />}
      <ListPage<Role>
        title="角色权限"
        endpoint={EP.role}
        shape="flat"
        queryKey="roles"
        columns={columns}
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
            新建角色
          </Button>
        }
      />

      <FormModal
        open={modalOpen}
        title={editing ? `编辑角色 · ${editing.name}` : '新建角色'}
        fields={fields}
        initial={editing ? { ...editing } : { status: 1 }}
        onClose={() => setModalOpen(false)}
        onSubmit={save}
        width={720}
      />

      <PasswordPrompt
        open={Boolean(pending)}
        title={`删除角色「${pending?.name ?? ''}」`}
        hint="删除后该角色的用户关联与权限关联会一并解除，请输入登录密码确认。"
        onCancel={() => setPending(null)}
        onOk={async (password) => {
          if (!pending) return
          await api.del(item(EP.role, pending.id), password)
          message.success('删除成功')
          await invalidate()
        }}
      />
    </>
  )
}
