// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { App, Button, Card, Descriptions, Divider, Drawer, Flex, Form, Input, Tabs, Typography } from 'antd'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../api/client'
import { EP, item } from '../api/endpoints'
import type { LogRow, SystemConfigItem } from '../api/types'
import ListPage, { type Column, type Filter } from '../components/ListPage'
import FormModal, { type Field } from '../components/FormModal'
import { LOG_SOURCES } from '../components/StatusTag'
import { EmptyState } from '../components/PetMark'
import PasswordPrompt from '../components/PasswordPrompt'
import { useAuth } from '../auth/store'

const TABS = ['config', 'logs', 'profile'] as const
type TabKey = (typeof TABS)[number]

export default function SystemPage() {
  const { tab } = useParams()
  const navigate = useNavigate()
  const active: TabKey = TABS.includes(tab as TabKey) ? (tab as TabKey) : 'config'

  return (
    <Card styles={{ body: { paddingTop: 8 } }}>
      <Tabs
        activeKey={active}
        onChange={(key) => navigate(`/system/${key}`)}
        items={[
          { key: 'config', label: '系统配置', children: <ConfigTab /> },
          { key: 'logs', label: '操作日志', children: <LogsTab /> },
          { key: 'profile', label: '个人中心', children: <ProfileTab /> },
        ]}
      />
    </Card>
  )
}

// 列集与列宽两端统一（规范 §1.3 + lead 2026-10-03 裁决）：分组 / 配置键 / 配置值 / 类型 / 说明 / 更新时间。
// 配置值 · 说明 是长文本列，带 cell-ellipsis（见 index.css），240 让声明宽成为硬约束；
// 240 不是随手挑的：本表声明和 = 1050（含更新时间 150 -> 1200，超过容器 1068 会横向滚动，见 README 的溢出说明）。
const configColumns: Column<SystemConfigItem>[] = [
  { title: '分组', key: 'group', width: 140 },
  { title: '配置键', key: 'key', width: 180 },
  { title: '配置值', key: 'value', width: 240, ellipsis: true },
  { title: '类型', key: 'type', width: 100 },
  { title: '说明', key: 'description', width: 240, ellipsis: true },
  { title: '更新时间', key: 'updated_at', width: 150 },
]

// 值类型是字符串枚举，取值以 docs/install.sql:112 的列 COMMENT 为准（`string|int|bool|json|array`）。
// 此前这里是文本框、占位符写的是「string / number / boolean / json」：number/boolean 不是库里认的关键字，
// 照提示填反而写进错值，还漏了 array —— 改成与 SQL（及 Angular CONFIG_TYPES）一致的下拉。
const CONFIG_TYPES = ['string', 'int', 'bool', 'json', 'array'].map((value) => ({ label: value, value }))

const configFields: Field[] = [
  { name: 'group', label: '分组', required: true },
  { name: 'key', label: '键', required: true },
  { name: 'type', label: '值类型', type: 'select', options: CONFIG_TYPES, placeholder: '留空按 string 处理' },
  { name: 'value', label: '值', type: 'textarea', required: true },
  { name: 'description', label: '说明', type: 'textarea' },
]

function ConfigTab() {
  const { message } = App.useApp()
  const queryClient = useQueryClient()
  const [editing, setEditing] = useState<SystemConfigItem | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [pending, setPending] = useState<SystemConfigItem | null>(null)
  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['configs'] })

  return (
    <>
      <ListPage<SystemConfigItem>
        endpoint={EP.config}
        shape="flat"
        queryKey="configs"
        columns={configColumns}
        filters={[{ name: 'group', label: '按分组精确筛选' }]}
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
            新建配置
          </Button>
        }
      />

      <FormModal
        open={modalOpen}
        title={editing ? `编辑配置 · ${editing.group}.${editing.key}` : '新建配置'}
        fields={editing ? configFields.filter((f) => !['group', 'key'].includes(f.name)) : configFields}
        initial={editing ? { ...editing } : { type: 'string' }}
        onClose={() => setModalOpen(false)}
        onSubmit={async (values) => {
          if (editing) await api.put(item(EP.config, editing.id), values)
          else await api.post(EP.config, values)
          message.success(editing ? '更新成功' : '创建成功')
          await invalidate()
        }}
      />

      <PasswordPrompt
        open={Boolean(pending)}
        title={`删除配置「${pending?.group ?? ''}.${pending?.key ?? ''}」`}
        onCancel={() => setPending(null)}
        onOk={async (password) => {
          if (!pending) return
          await api.del(item(EP.config, pending.id), password)
          message.success('删除成功')
          await invalidate()
        }}
      />
    </>
  )
}

// 列宽显式声明（规范 §1.3）：数值对齐 Angular logs.ts（请求路径 260 两端同值）。
// 表头用显式文案（lead 2026-10-03 裁定）：请求路径 / 操作时间 —— 与筛选区 label、Angular 详情抽屉的措辞一致
const logColumns: Column<LogRow>[] = [
  { title: '操作人', key: 'user_name', width: 130 },
  { title: '动作', key: 'action', width: 180 },
  { title: '方法', key: 'method', width: 90 },
  { title: '请求路径', key: 'path', width: 260 },
  { title: 'IP', key: 'ip', width: 140 },
  // 来源端是字符串枚举（install.sql:560），后端透传小写标识，映射成展示名再显示（同 Angular logs.ts 的 LOG_SOURCES）
  { title: '来源端', key: 'source', width: 110, render: (row) => LOG_SOURCES[row.source] ?? row.source },
  { title: '操作时间', key: 'created_at', width: 160 },
]

const logFilters: Filter[] = [
  { name: 'action', label: '动作' },
  { name: 'path', label: '请求路径' },
  { name: 'start_date', endName: 'end_date', label: '时间范围', type: 'dateRange' },
]

/** 请求参数是后端存的 JSON 字符串；解析不动就原样展示（与 Angular logs.ts 的 pretty 同语义） */
function prettyJson(raw?: string): string {
  if (!raw) return '—'
  try {
    return JSON.stringify(JSON.parse(raw), null, 2)
  } catch {
    return raw
  }
}

function LogsTab() {
  const [detail, setDetail] = useState<LogRow | null>(null)
  return (
    <>
      <ListPage<LogRow>
        endpoint={EP.log}
        shape="flat"
        queryKey="logs"
        columns={logColumns}
        filters={logFilters}
        // 详情：看列表放不下的「请求参数」（与 Angular logs.ts 同一行操作，操作列因此两端都有）
        rowActions={(row) => [
          <Button key="detail" type="link" size="small" onClick={() => setDetail(row)}>
            详情
          </Button>,
        ]}
      />
      <Drawer open={Boolean(detail)} size={520} title="日志详情" onClose={() => setDetail(null)}>
        {detail ? (
          <Descriptions column={1} size="small" bordered>
            <Descriptions.Item label="操作人">{detail.user_name || '—'}</Descriptions.Item>
            <Descriptions.Item label="方法">{detail.method}</Descriptions.Item>
            <Descriptions.Item label="动作">{detail.action}</Descriptions.Item>
            <Descriptions.Item label="IP">{detail.ip || '—'}</Descriptions.Item>
            <Descriptions.Item label="请求路径">
              <code>{detail.path}</code>
            </Descriptions.Item>
            <Descriptions.Item label="操作时间">{detail.created_at}</Descriptions.Item>
            <Descriptions.Item label="请求参数">
              <pre className="params">{prettyJson(detail.input)}</pre>
            </Descriptions.Item>
          </Descriptions>
        ) : (
          <EmptyState description="暂无详情" />
        )}
      </Drawer>
    </>
  )
}

interface ProfileShape {
  id: string
  username: string
  real_name: string
  phone: string
  email: string
  last_login_at?: string
}

function ProfileTab() {
  const { message } = App.useApp()
  const user = useAuth((s) => s.user)
  const clear = useAuth((s) => s.clear)
  const navigate = useNavigate()
  const [profileForm] = Form.useForm<{ real_name: string; phone: string; email: string }>()
  const [passwordForm] = Form.useForm<{ old_password: string; new_password: string; confirm: string }>()
  const [saving, setSaving] = useState(false)

  const profile = useQuery({
    queryKey: ['profile'],
    queryFn: async () => {
      const data = await api.get<ProfileShape>(EP.profile)
      profileForm.setFieldsValue({ real_name: data.real_name, phone: data.phone, email: data.email })
      return data
    },
  })

  const saveProfile = async (values: { real_name: string; phone: string; email: string }) => {
    setSaving(true)
    try {
      await api.put(EP.profile, values)
      message.success('资料已更新')
      await profile.refetch()
    } catch (err) {
      message.error(err instanceof Error ? err.message : '更新失败')
    } finally {
      setSaving(false)
    }
  }

  const savePassword = async (values: { old_password: string; new_password: string }) => {
    try {
      await api.put(EP.profilePassword, { old_password: values.old_password, new_password: values.new_password })
      message.success('密码已修改')
      passwordForm.resetFields()
    } catch (err) {
      message.error(err instanceof Error ? err.message : '修改失败')
    }
  }

  const logout = async () => {
    try {
      await api.post(EP.profileLogout)
    } catch {
      // 忽略登出接口错误
    }
    clear()
    navigate('/login', { replace: true })
  }

  return (
    <Flex vertical gap={16} style={{ maxWidth: 520 }}>
      <Typography.Text type="secondary">
        当前账号：{profile.data?.username || user?.username}　最近登录：{profile.data?.last_login_at || '—'}
      </Typography.Text>

      <Form form={profileForm} layout="vertical" onFinish={(values) => void saveProfile(values)}>
        <Form.Item name="real_name" label="姓名" rules={[{ required: true, message: '请输入姓名' }]}>
          <Input />
        </Form.Item>
        <Form.Item name="phone" label="手机号">
          <Input />
        </Form.Item>
        <Form.Item name="email" label="邮箱">
          <Input />
        </Form.Item>
        <Button type="primary" htmlType="submit" loading={saving}>
          保存资料
        </Button>
      </Form>

      <Divider style={{ margin: 0 }} />

      <Form form={passwordForm} layout="vertical" onFinish={(values) => void savePassword(values)}>
        <Form.Item name="old_password" label="当前密码" rules={[{ required: true, message: '请输入当前密码' }]}>
          <Input.Password autoComplete="current-password" />
        </Form.Item>
        <Form.Item
          name="new_password"
          label="新密码"
          rules={[
            { required: true, message: '请输入新密码' },
            {
              pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,32}$/,
              message: '8-32 位，含大小写字母、数字与特殊字符 @$!%*?&',
            },
          ]}
        >
          <Input.Password autoComplete="new-password" />
        </Form.Item>
        <Form.Item
          name="confirm"
          label="确认新密码"
          dependencies={['new_password']}
          rules={[
            { required: true, message: '请再次输入新密码' },
            ({ getFieldValue }) => ({
              validator: (_, value) =>
                !value || getFieldValue('new_password') === value ? Promise.resolve() : Promise.reject(new Error('两次输入不一致')),
            }),
          ]}
        >
          <Input.Password autoComplete="new-password" />
        </Form.Item>
        <Flex gap={8}>
          <Button type="primary" htmlType="submit">
            修改密码
          </Button>
          <Button danger onClick={() => void logout()}>
            退出登录
          </Button>
        </Flex>
      </Form>
    </Flex>
  )
}
