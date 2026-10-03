// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useMemo, useState } from 'react'
import { App, Button, Card, Flex, Input, Space, Tabs, Tree } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import { useRoomTree } from '../api/lookups'
import type { Room, TreeCommunity } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import PasswordPrompt from '../components/PasswordPrompt'
import { STATUS_MAPS, StatusTag, statusText, toOptions } from '../components/StatusTag'
import { EmptyState } from '../components/PetMark'

export default function RoomsPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const tree = useRoomTree()
  const [editing, setEditing] = useState<Room | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [pending, setPending] = useState<Room | null>(null)
  const [formCommunity, setFormCommunity] = useState<string | undefined>(undefined)
  const [formBuilding, setFormBuilding] = useState<string | undefined>(undefined)
  const [search, setSearch] = useState('')

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['rooms'] })

  // 列宽显式声明（规范 §1.3）：数值对齐 Angular rooms.ts；★ 三列（小区/楼栋/单元）Angular 无同名列，为本端定值。
  const columns: Column<Room>[] = [
    { title: '房号', key: 'room_number', width: 140 },
    { title: '小区', key: 'community_id', width: 150, render: (row) => tree.communityName.get(row.community_id) ?? row.community_id }, // ★
    { title: '楼栋', key: 'building_id', width: 100, render: (row) => tree.buildingName.get(row.building_id) ?? '—' }, // ★
    { title: '单元', key: 'unit_id', width: 100, render: (row) => tree.unitName.get(row.unit_id) ?? '—' }, // ★
    { title: '楼层', key: 'floor', width: 80, align: 'right' },
    { title: '总面积(m²)', key: 'area_total', width: 120, align: 'right' },
    // 列集并集（lead 2026-10-03）：套内是 Angular 独有的列，宽度取 Angular rooms.ts 的 110
    { title: '套内(m²)', key: 'area_indoor', width: 110, align: 'right' },
    { title: '朝向', key: 'orientation', width: 90 },
    { title: '用途', key: 'usage_type', width: 100, render: (row) => statusText(row.usage_type, STATUS_MAPS.usageType) },
    { title: '状态', key: 'status', width: 100, render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.room} /> },
    { title: '创建时间', key: 'created_at', width: 150 },
  ]

  const filters: Filter[] = [
    { name: 'keyword', label: '搜索房号' },
    { name: 'community_id', label: '小区', type: 'select', options: [...tree.communityName].map(([value, label]) => ({ label, value })), width: 200 },
    { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.room) },
  ]

  const fields: Field[] = [
    {
      name: 'community_id',
      label: '所属小区',
      type: 'select',
      required: true,
      options: [...tree.communityName].map(([value, label]) => ({ label, value })),
    },
    {
      name: 'building_id',
      label: '所属楼栋',
      type: 'select',
      required: true,
      options: formCommunity ? tree.buildingsOf.get(formCommunity) ?? [] : [],
    },
    {
      name: 'unit_id',
      label: '所属单元',
      type: 'select',
      required: true,
      options: formBuilding ? tree.unitsOf.get(formBuilding) ?? [] : [],
    },
    { name: 'room_number', label: '房号', required: true },
    { name: 'floor', label: '楼层', type: 'number' },
    { name: 'area_indoor', label: '套内面积(m²)', type: 'number' },
    { name: 'area_shared', label: '公摊面积(m²)', type: 'number' },
    { name: 'area_total', label: '总面积(m²)', type: 'number' },
    { name: 'orientation', label: '朝向' },
    { name: 'decoration', label: '装修', type: 'select', options: toOptions(STATUS_MAPS.decoration) },
    { name: 'usage_type', label: '用途', type: 'select', options: toOptions(STATUS_MAPS.usageType) },
    { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.room) },
    { name: 'remark', label: '备注', type: 'textarea' },
  ]

  const openCreate = () => {
    setEditing(null)
    setFormCommunity(undefined)
    setFormBuilding(undefined)
    setModalOpen(true)
  }

  const openEdit = (row: Room) => {
    setEditing(row)
    setFormCommunity(row.community_id)
    setFormBuilding(row.building_id)
    setModalOpen(true)
  }

  const save = async (values: Record<string, unknown>) => {
    if (editing) await api.put(item(EP.room, editing.id), values)
    else await api.post(EP.room, values)
    message.success(editing ? '更新成功' : '创建成功')
    await invalidate()
  }

  const treeData = useMemo(() => toTreeData(tree.tree), [tree.tree])
  const filteredTree = useMemo(() => filterTree(treeData, search.trim()), [treeData, search])

  return (
    <Flex vertical gap={16}>
      <Tabs
        items={[
          {
            key: 'list',
            label: '房产列表',
            children: (
              <ListPage<Room>
                endpoint={EP.room}
                queryKey="rooms"
                columns={columns}
                filters={filters}
                rowActions={(row) => [
                  <Button key="edit" type="link" size="small" onClick={() => openEdit(row)}>
                    编辑
                  </Button>,
                  <Button key="del" type="link" size="small" danger onClick={() => setPending(row)}>
                    删除
                  </Button>,
                ]}
                toolbar={<Button type="primary" onClick={openCreate}>新建房产</Button>}
              />
            ),
          },
          {
            key: 'tree',
            label: '小区结构树',
            children: (
              <Card styles={{ body: { padding: 16 } }}>
                <Input.Search
                  allowClear
                  placeholder="搜索小区 / 楼栋 / 单元 / 房号"
                  style={{ maxWidth: 320, marginBottom: 16 }}
                  onSearch={setSearch}
                />
                {filteredTree.length ? (
                  <Tree
                    showLine
                    blockNode
                    defaultExpandAll
                    treeData={filteredTree}
                    titleRender={(node) => (
                      <Space size={8}>
                        <span>{String(node.title)}</span>
                        {node.roomStatus !== undefined && (
                          <StatusTag value={node.roomStatus} list={STATUS_MAPS.room} />
                        )}
                      </Space>
                    )}
                  />
                ) : (
                  <EmptyState description="暂无结构数据" />
                )}
              </Card>
            ),
          },
        ]}
      />

      <FormModal
        open={modalOpen}
        title={editing ? `编辑房产 · ${editing.room_number}` : '新建房产'}
        fields={fields}
        initial={editing ? { ...editing } : { status: 0, usage_type: 1 }}
        onClose={() => setModalOpen(false)}
        onSubmit={save}
        onValuesChange={(changed) => {
          if (changed.community_id !== undefined) setFormCommunity(changed.community_id as string)
          if (changed.building_id !== undefined) setFormBuilding(changed.building_id as string)
        }}
        width={720}
      />

      <PasswordPrompt
        open={Boolean(pending)}
        title={`删除房产「${pending?.room_number ?? ''}」`}
        onCancel={() => setPending(null)}
        onOk={async (password) => {
          if (!pending) return
          await api.del(item(EP.room, pending.id), password)
          message.success('删除成功')
          await invalidate()
          await queryClient.invalidateQueries({ queryKey: ['lookup', 'room-tree'] })
        }}
      />
    </Flex>
  )
}

interface RoomTreeNode {
  key: string
  title: string
  roomStatus?: number
  children?: RoomTreeNode[]
}

function toTreeData(nodes: TreeCommunity[]): RoomTreeNode[] {
  return nodes.map((community) => ({
    key: community.id,
    title: community.name,
    children: community.children.map((building) => ({
      key: building.id,
      title: building.name,
      children: building.children.map((unit) => ({
        key: unit.id,
        title: unit.name,
        children: unit.children.map((room) => ({
          key: room.id,
          title: room.name,
          roomStatus: room.status,
        })),
      })),
    })),
  }))
}

/** 搜索时保留命中节点及其祖先路径 */
function filterTree(nodes: RoomTreeNode[], keyword: string): RoomTreeNode[] {
  if (!keyword) return nodes
  const result: RoomTreeNode[] = []
  for (const node of nodes) {
    const children = filterTree(node.children ?? [], keyword)
    if (children.length || node.title.includes(keyword)) {
      result.push({ ...node, children: children.length ? children : node.children })
    }
  }
  return result
}
