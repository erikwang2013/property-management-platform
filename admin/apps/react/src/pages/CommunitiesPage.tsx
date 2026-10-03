// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import type { Community } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import PasswordPrompt from '../components/PasswordPrompt'
import { STATUS_MAPS, StatusTag, toOptions } from '../components/StatusTag'

// 列宽显式声明（规范 §1.3）：逐列对齐 Angular communities.ts（含名称 180 / 地址 220，两端同值；README「全站列宽」）。
const columns: Column<Community>[] = [
  { title: '小区名称', key: 'name', width: 180 },
  { title: '城市', key: 'city', width: 120 },
  { title: '地址', key: 'address', width: 220 },
  { title: '楼栋数', key: 'building_count', width: 90, align: 'right' },
  { title: '房屋套数', key: 'room_count', width: 90, align: 'right' },
  { title: '物业公司', key: 'property_company', width: 160 },
  { title: '状态', key: 'status', width: 100, render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.normal} /> },
  { title: '创建时间', key: 'created_at', width: 150 },
]

const filters: Filter[] = [
  { name: 'keyword', label: '搜索小区名称' },
  { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.normal) },
]

const fields: Field[] = [
  { name: 'name', label: '小区名称', required: true },
  { name: 'city', label: '城市' },
  { name: 'province', label: '省份' },
  { name: 'district', label: '区县' },
  { name: 'address', label: '详细地址', full: true },
  { name: 'area_total', label: '总建筑面积(m²)', type: 'number' },
  { name: 'developer', label: '开发商' },
  { name: 'property_company', label: '物业公司' },
  { name: 'contact_phone', label: '联系电话' },
  { name: 'description', label: '简介', type: 'textarea' },
]

export default function CommunitiesPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const [editing, setEditing] = useState<Community | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [pending, setPending] = useState<Community | null>(null)

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['communities'] })

  const save = async (values: Record<string, unknown>) => {
    if (editing) await api.put(item(EP.community, editing.id), values)
    else await api.post(EP.community, values)
    message.success(editing ? '更新成功' : '创建成功')
    await invalidate()
  }

  return (
    <>
      <ListPage<Community>
        title="小区管理"
        endpoint={EP.community}
        queryKey="communities"
        columns={columns}
        filters={filters}
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
            新建小区
          </Button>
        }
      />

      <FormModal
        open={modalOpen}
        title={editing ? `编辑小区 · ${editing.name}` : '新建小区'}
        fields={fields}
        initial={editing ? { ...editing } : undefined}
        onClose={() => setModalOpen(false)}
        onSubmit={save}
      />

      <PasswordPrompt
        open={Boolean(pending)}
        title={`删除小区「${pending?.name ?? ''}」`}
        onCancel={() => setPending(null)}
        onOk={async (password) => {
          if (!pending) return
          await api.del(item(EP.community, pending.id), password)
          message.success('删除成功')
          await invalidate()
        }}
      />
    </>
  )
}
