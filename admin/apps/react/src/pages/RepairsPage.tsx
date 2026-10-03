// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button, Descriptions, Drawer, Image, Space, Timeline } from 'antd'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import { useOwners, useRoomTree, useStaffRoster } from '../api/lookups'
import type { Repair, RepairDetail } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import RemoteSelect from '../components/RemoteSelect'
import { STATUS_MAPS, StatusTag, statusText, toOptions } from '../components/StatusTag'
import { EmptyState } from '../components/PetMark'

export default function RepairsPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const tree = useRoomTree()
  const owners = useOwners()
  const roster = useStaffRoster()

  const [createOpen, setCreateOpen] = useState(false)
  const [assigning, setAssigning] = useState<Repair | null>(null)
  const [progressing, setProgressing] = useState<Repair | null>(null)
  const [detailId, setDetailId] = useState<string | null>(null)

  const detail = useQuery({
    queryKey: ['repair-detail', detailId],
    queryFn: () => api.get<RepairDetail>(item(EP.repair, detailId as string)),
    enabled: Boolean(detailId),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['repairs'] })

  // 列集与列序为两端共同约定（规格 §5 报修）：工单号·房产·类别·紧急度·问题描述·状态·维修人员·完成时间·创建时间·操作。
  // 增删列必须两端同步；联系电话不在列集内（详情抽屉里有），别单边加回来。
  // 每列显式声明宽度（规范 §1.3）：宽度与列序都是两端共同约定，数值对齐 Angular 的实测值，改动必须两端同步。
  // 「问题描述」另带 ellipsis —— 长文本列只写 width 会被内容顶开（见 index.css 的 .cell-ellipsis）。
  const columns: Column<Repair>[] = [
    { title: '工单号', key: 'order_number', width: 140 },
    { title: '房产', key: 'room_id', width: 150, render: (row) => tree.roomName(row.room_id) || row.room_id },
    { title: '类别', key: 'category', width: 84, render: (row) => statusText(row.category, STATUS_MAPS.repairCategory) },
    { title: '紧急度', key: 'urgency', width: 84, render: (row) => <StatusTag value={row.urgency} list={STATUS_MAPS.urgency} /> },
    { title: '问题描述', key: 'description', width: 220, ellipsis: true },
    { title: '状态', key: 'status', width: 90, render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.repair} /> },
    { title: '维修人员', key: 'staff_id', width: 100, render: (row) => row.staff_name || '—' },
    { title: '完成时间', key: 'completed_at', width: 150 },
    { title: '创建时间', key: 'created_at', width: 150 },
  ]

  // 筛选区文案与列标题统一（工单号 / 状态 / 类别），别一处叫报修编号、一处叫分类
  const filters: Filter[] = [
    { name: 'keyword', label: '输入工单号搜索' },
    { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.repair) },
    { name: 'category', label: '类别', type: 'select', options: toOptions(STATUS_MAPS.repairCategory), width: 140 },
  ]

  const createFields: Field[] = [
    {
      name: 'room_id',
      label: '报修房产',
      type: 'custom',
      required: true,
      render: () => (
        <RemoteSelect
          endpoint={EP.room}
          queryKey="repair-room-search"
          toOption={(row) => ({ label: String(row.room_number), value: String(row.id) })}
          placeholder="搜索房号"
        />
      ),
    },
    { name: 'owner_id', label: '报修人', type: 'select', options: owners.options },
    { name: 'contact_phone', label: '联系电话', required: true },
    { name: 'category', label: '分类', type: 'select', options: toOptions(STATUS_MAPS.repairCategory) },
    { name: 'urgency', label: '紧急程度', type: 'select', options: toOptions(STATUS_MAPS.urgency) },
    { name: 'scheduled_at', label: '预约上门', type: 'date' },
    { name: 'description', label: '问题描述', type: 'textarea' },
  ]

  // 派单/改派：直接选人，提交 /admin/staff 回的 hashid（后端 2026-10-03 起收 hashid）。
  // 只挡离职（status 0）；休假的（2）仍可派。
  const staffOptions = (roster.data?.rows ?? [])
    .filter((s) => s.status !== 0)
    .map((s) => ({ label: `${s.name}${s.job_title ? `（${s.job_title}）` : ''}`, value: s.id }))

  const assignFields: Field[] = [
    { name: 'staff_id', label: '维修人员', type: 'select', required: true, options: staffOptions, full: true },
    { name: 'remark', label: '派单说明', type: 'textarea' },
  ]

  const progressFields: Field[] = [
    { name: 'status', label: '变更后状态', type: 'select', required: true, options: toOptions(STATUS_MAPS.repair) },
    { name: 'remark', label: '进度说明', type: 'textarea', required: true },
  ]

  return (
    <>
      <ListPage<Repair>
        title="报修管理"
        endpoint={EP.repair}
        queryKey="repairs"
        columns={columns}
        filters={filters}
        rowActions={(row) => [
          <Button key="detail" type="link" size="small" onClick={() => setDetailId(row.id)}>
            详情
          </Button>,
          // 已完成 / 已评价 / 已取消的单子不再需要派单与进度上报（与 Angular repairs.ts 的 settled() 同口径）。
          // 后端 assign 只拦取消、progress 只拦部分转移，比这里宽 —— UI 收严是有意的：误改已闭环记录比少一个入口更糟。
          ...(row.status < 3
            ? [
                <Button key="assign" type="link" size="small" onClick={() => setAssigning(row)}>
                  派单
                </Button>,
                <Button key="progress" type="link" size="small" onClick={() => setProgressing(row)}>
                  进度
                </Button>,
              ]
            : []),
        ]}
        toolbar={
          <Button type="primary" onClick={() => setCreateOpen(true)}>
            新建报修单
          </Button>
        }
      />

      <FormModal
        open={createOpen}
        title="新建报修单"
        fields={createFields}
        // 不做类别/紧急度预选：类别是派单依据，预选等于替提交人做判断，容易整批错单（lead 2026-10-03 裁定，与 Angular 同）
        onClose={() => setCreateOpen(false)}
        onSubmit={async (values) => {
          // 显式挑字段 + 空值不发（与 Angular repairs.ts 的 actionSubmit 同口径）：
          // 后端 store 收 `only([...])` 后直接 create，空串会被当值写库 —— 落进 datetime/number 列即类型错；
          // 省略该键则保留后端默认（category/urgency 的数据库默认值）。
          const optional = (key: string) => values[key] || undefined
          await api.post(EP.repair, {
            room_id: String(values.room_id ?? ''),
            contact_phone: String(values.contact_phone ?? ''),
            owner_id: optional('owner_id'),
            category: optional('category'),
            urgency: optional('urgency'),
            scheduled_at: optional('scheduled_at'),
            description: optional('description'),
          })
          message.success('创建成功（状态：待派单）')
          await invalidate()
        }}
        width={720}
      />

      <FormModal
        open={Boolean(assigning)}
        title={`派单 · ${assigning?.order_number ?? ''}`}
        fields={assignFields}
        onClose={() => setAssigning(null)}
        onSubmit={async (values) => {
          if (!assigning) return
          await api.put(item(EP.repair, assigning.id) + '/assign', values)
          message.success('派单成功')
          await invalidate()
        }}
        width={640}
      />

      <FormModal
        open={Boolean(progressing)}
        title={`进度上报 · ${progressing?.order_number ?? ''}`}
        fields={progressFields}
        onClose={() => setProgressing(null)}
        onSubmit={async (values) => {
          if (!progressing) return
          await api.post(item(EP.repair, progressing.id) + '/progress', values)
          message.success('进度已更新')
          await invalidate()
        }}
        width={560}
      />

      <Drawer
        open={Boolean(detailId)}
        size={520}
        title="报修详情"
        onClose={() => setDetailId(null)}
        loading={detail.isFetching}
      >
        {detail.data ? (
          <Space orientation="vertical" size={16} style={{ width: '100%' }}>
            {/* 项目与顺序对齐 Angular repairs.html 的抽屉：类别 · 紧急度 · 状态 · 维修人员 · 问题描述 · 图片 · 预约 · 完成 · 评价 */}
            <Descriptions column={1} size="small" bordered>
              <Descriptions.Item label="编号">{detail.data.order_number}</Descriptions.Item>
              <Descriptions.Item label="房产">{tree.roomName(detail.data.room_id) || detail.data.room_id}</Descriptions.Item>
              <Descriptions.Item label="联系电话">{detail.data.contact_phone || '—'}</Descriptions.Item>
              <Descriptions.Item label="类别">{statusText(detail.data.category, STATUS_MAPS.repairCategory)}</Descriptions.Item>
              <Descriptions.Item label="紧急度">
                <StatusTag value={detail.data.urgency} list={STATUS_MAPS.urgency} />
              </Descriptions.Item>
              <Descriptions.Item label="状态">
                <StatusTag value={detail.data.status} list={STATUS_MAPS.repair} />
              </Descriptions.Item>
              <Descriptions.Item label="维修人员">{detail.data.staff_name || '—'}</Descriptions.Item>
              <Descriptions.Item label="问题描述">{detail.data.description || '—'}</Descriptions.Item>
              {/* 后端 images 可空，空数组时整行不渲染（Angular 同为 @if (d.images?.length)） */}
              {detail.data.images?.length ? (
                <Descriptions.Item label="图片">
                  <Image.PreviewGroup>
                    <Space wrap size={8}>
                      {detail.data.images.map((src) => (
                        <Image
                          key={src}
                          src={src}
                          alt="报修图片"
                          width={72}
                          height={72}
                          style={{ objectFit: 'cover', borderRadius: 6 }}
                        />
                      ))}
                    </Space>
                  </Image.PreviewGroup>
                </Descriptions.Item>
              ) : null}
              <Descriptions.Item label="预约时间">{detail.data.scheduled_at || '—'}</Descriptions.Item>
              <Descriptions.Item label="完成时间">{detail.data.completed_at || '—'}</Descriptions.Item>
              <Descriptions.Item label="评价">{detail.data.feedback || (detail.data.rating ? `${detail.data.rating} 星` : '—')}</Descriptions.Item>
            </Descriptions>
            <Timeline
              items={(detail.data.progress ?? []).map((p) => ({
                content: `${statusText(p.status_from, STATUS_MAPS.repair)} → ${statusText(p.status_to, STATUS_MAPS.repair)}　${p.remark || ''}（${p.created_at}）`,
              }))}
            />
          </Space>
        ) : (
          <EmptyState description="暂无详情" />
        )}
      </Drawer>
    </>
  )
}
