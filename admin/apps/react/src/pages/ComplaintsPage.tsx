// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { App, Button, Descriptions, Drawer, Space, Timeline } from 'antd'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import type { Complaint, ComplaintDetail } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import { STATUS_MAPS, StatusTag, toOptions } from '../components/StatusTag'
import { EmptyState } from '../components/PetMark'

export default function ComplaintsPage() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const [handling, setHandling] = useState<Complaint | null>(null)
  const [visiting, setVisiting] = useState<Complaint | null>(null)
  const [detailId, setDetailId] = useState<string | null>(null)

  const detail = useQuery({
    queryKey: ['complaint-detail', detailId],
    queryFn: () => api.get<ComplaintDetail>(item(EP.complaint, detailId as string)),
    enabled: Boolean(detailId),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['complaints'] })

  // 列宽显式声明（规范 §1.3）：数值对齐 Angular complaints.ts；★ 满意度是 Angular 列表里没有的列，本端定值。
  const columns: Column<Complaint>[] = [
    { title: '标题', key: 'title', width: 220 },
    { title: '类型', key: 'type', width: 90, render: (row) => <StatusTag value={row.type} list={STATUS_MAPS.complaintType} /> },
    // 分类是数值枚举（1=服务态度 … 7=其他），必须过映射，否则表格里出现裸数字
    { title: '分类', key: 'category', width: 110, render: (row) => <StatusTag value={row.category} list={STATUS_MAPS.complaintCategory} /> },
    {
      title: '状态',
      key: 'status',
      width: 100,
      render: (row) => <StatusTag value={row.status} list={STATUS_MAPS.complaint} />,
    },
    // 实名/匿名都挂标（0 实名 / 1 匿名）：0 是有意义的取值，不是空值 —— 「空值一律 —」不适用本列
    { title: '匿名', key: 'is_anonymous', width: 90, render: (row) => <StatusTag value={row.is_anonymous} list={STATUS_MAPS.anonymous} /> },
    { title: '受理时间', key: 'handled_at', width: 150 },
    { title: '满意度', key: 'satisfaction', width: 90, align: 'right' }, // ★
    { title: '创建时间', key: 'created_at', width: 150 },
  ]

  const filters: Filter[] = [
    { name: 'type', label: '类型', type: 'select', options: toOptions(STATUS_MAPS.complaintType) },
    { name: 'status', label: '状态', type: 'select', options: toOptions(STATUS_MAPS.complaint) },
  ]

  const handleFields: Field[] = [
    { name: 'handler_remark', label: '受理说明', type: 'textarea', required: true },
  ]
  const visitFields: Field[] = [
    { name: 'visitor_remark', label: '回访记录', type: 'textarea', required: true },
  ]

  return (
    <>
      <ListPage<Complaint>
        title="投诉管理"
        endpoint={EP.complaint}
        queryKey="complaints"
        columns={columns}
        filters={filters}
        rowActions={(row) => [
          <Button
            key="detail"
            type="link"
            size="small"
            onClick={() => {
              setDetailId(row.id)
            }}
          >
            详情
          </Button>,
          // 可见性与后端守卫同编号（2026-10-03 后端把守卫改成 SQL 编号）：受理 = 待处理(0)，
          // 回访 = 处理中(1)。前端只做「显不显示」，真正的准入仍由守卫判（不符会回 422）。
          ...(row.status === 0
            ? [
                <Button key="handle" type="link" size="small" onClick={() => setHandling(row)}>
                  受理
                </Button>,
              ]
            : []),
          ...(row.status === 1
            ? [
                <Button key="visit" type="link" size="small" onClick={() => setVisiting(row)}>
                  回访
                </Button>,
              ]
            : []),
        ]}
      />

      <FormModal
        open={Boolean(handling)}
        title={`受理投诉 · ${handling?.title ?? ''}`}
        fields={handleFields}
        onClose={() => setHandling(null)}
        onSubmit={async (values) => {
          if (!handling) return
          await api.put(item(EP.complaint, handling.id) + '/handle', values)
          message.success('投诉已受理（状态：处理中）')
          await invalidate()
        }}
        width={560}
      />

      <FormModal
        open={Boolean(visiting)}
        title={`回访投诉 · ${visiting?.title ?? ''}`}
        fields={visitFields}
        onClose={() => setVisiting(null)}
        onSubmit={async (values) => {
          if (!visiting) return
          await api.post(item(EP.complaint, visiting.id) + '/visit', values)
          message.success('回访完成（状态：已回访）')
          await invalidate()
        }}
        width={560}
      />

      <Drawer
        open={Boolean(detailId)}
        size={520}
        title="投诉详情"
        onClose={() => setDetailId(null)}
        loading={detail.isFetching}
      >
        {detail.data ? (
          <Space orientation="vertical" size={16} style={{ width: '100%' }}>
            <Descriptions column={1} size="small" bordered>
              <Descriptions.Item label="标题">{detail.data.title}</Descriptions.Item>
              <Descriptions.Item label="内容">{detail.data.content || '—'}</Descriptions.Item>
              <Descriptions.Item label="状态">
                <StatusTag value={detail.data.status} list={STATUS_MAPS.complaint} />
              </Descriptions.Item>
              <Descriptions.Item label="受理说明">{detail.data.handler_remark || '—'}</Descriptions.Item>
              <Descriptions.Item label="回访记录">{detail.data.visitor_remark || '—'}</Descriptions.Item>
              <Descriptions.Item label="满意度">{detail.data.satisfaction || '—'}</Descriptions.Item>
            </Descriptions>
            <Timeline
              items={[
                { content: `提交 · ${detail.data.created_at}` },
                ...(detail.data.handled_at ? [{ content: `受理 · ${detail.data.handled_at}` }] : []),
                ...(detail.data.visitor_at ? [{ content: `回访 · ${detail.data.visitor_at}` }] : []),
              ]}
            />
          </Space>
        ) : (
          <EmptyState description="暂无详情" />
        )}
      </Drawer>
    </>
  )
}
