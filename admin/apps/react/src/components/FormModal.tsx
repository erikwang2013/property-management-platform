// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useEffect, type ReactNode } from 'react'
import { App, Col, DatePicker, Form, Input, InputNumber, Modal, Row, Select, TreeSelect } from 'antd'
import type { Rule } from 'antd/es/form'
import dayjs from 'dayjs'

export interface TreeOption {
  title: string
  value: string
  children?: TreeOption[]
}

export interface Field {
  name: string
  label: string
  type?: 'text' | 'password' | 'number' | 'textarea' | 'select' | 'date' | 'treeSelect' | 'custom'
  /** type='custom' 时使用：返回受 Form.Item 接管的控件（需支持 value/onChange） */
  render?: () => ReactNode
  options?: { label: string; value: number | string }[]
  treeData?: TreeOption[]
  treeCheckable?: boolean
  required?: boolean
  rules?: Rule[]
  /** 占满整行（默认半行两列） */
  full?: boolean
  disabled?: boolean
  extra?: string
  placeholder?: string
}

export interface FormModalProps {
  open: boolean
  title: string
  fields: Field[]
  initial?: Record<string, unknown>
  onClose: () => void
  onSubmit: (values: Record<string, unknown>) => Promise<void>
  /** 级联表单用：字段变化时通知父组件（如小区 → 楼栋 → 单元） */
  onValuesChange?: (changed: Record<string, unknown>, all: Record<string, unknown>) => void
  width?: number
}

/** 通用表单弹窗：字段描述驱动，9 个模块复用；日期在提交时统一转 YYYY-MM-DD */
export default function FormModal({
  open,
  title,
  fields,
  initial,
  onClose,
  onSubmit,
  onValuesChange,
  width = 640,
}: FormModalProps) {
  const { message } = App.useApp()
  const [form] = Form.useForm()

  useEffect(() => {
    if (!open) return
    const next: Record<string, unknown> = {}
    for (const f of fields) {
      const value = initial?.[f.name]
      next[f.name] = f.type === 'date' && value ? dayjs(String(value)) : value
    }
    form.setFieldsValue(next)
  }, [open, initial, fields, form])

  const submit = async () => {
    // 校验不过时 validateFields 会 reject 一个 ValidateErrorEntity（不是 Error 实例，控制台会打 pageerror Object）。
    // 调用处是 `onOk={() => void submit()}`，void 丢掉 promise 后无人接 rejection —— 字段下方的红字提示 antd 已给，
    // 这里吞掉即可（浏览器实测：空表单点保存曾出 pageerror，修后 console 干净）。
    const raw = await form.validateFields().catch(() => null)
    if (!raw) return
    const values: Record<string, unknown> = {}
    for (const f of fields) {
      const v = raw[f.name]
      values[f.name] =
        f.type === 'date' && dayjs.isDayjs(v) ? (v as dayjs.Dayjs).format('YYYY-MM-DD') : v
    }
    try {
      await onSubmit(values)
      onClose()
    } catch (err) {
      message.error(err instanceof Error ? err.message : '提交失败')
    }
  }

  return (
    <Modal
      open={open}
      title={title}
      width={width}
      onCancel={onClose}
      onOk={() => void submit()}
      okText="保存"
      cancelText="取消"
      // antd 6：maskClosable 已废弃，mask.closable 经 useMergedMask 归一后得到同一个布尔值
      mask={{ closable: false }}
    >
      <Form form={form} layout="vertical" style={{ marginTop: 8 }} onValuesChange={onValuesChange}>
        <Row gutter={16}>
          {fields.map((f) => (
            <Col span={f.full || f.type === 'textarea' ? 24 : 12} key={f.name}>
              <Form.Item
                name={f.name}
                label={f.label}
                extra={f.extra}
                rules={[
                  ...(f.required ? [{ required: true, message: `请填写${f.label}` }] : []),
                  ...(f.rules ?? []),
                ]}
              >
                {renderInput(f)}
              </Form.Item>
            </Col>
          ))}
        </Row>
      </Form>
    </Modal>
  )
}

function renderInput(f: Field) {
  switch (f.type) {
    case 'custom':
      return f.render?.()
    case 'password':
      return <Input.Password placeholder={f.placeholder} disabled={f.disabled} autoComplete="new-password" />
    case 'number':
      return <InputNumber style={{ width: '100%' }} placeholder={f.placeholder} disabled={f.disabled} />
    case 'textarea':
      return <Input.TextArea rows={3} placeholder={f.placeholder} disabled={f.disabled} />
    case 'select':
      return <Select allowClear options={f.options} placeholder={f.placeholder} disabled={f.disabled} />
    case 'date':
      return <DatePicker style={{ width: '100%' }} placeholder={f.placeholder} disabled={f.disabled} />
    case 'treeSelect':
      return (
        <TreeSelect
          treeData={f.treeData}
          treeCheckable={f.treeCheckable}
          showSearch
          treeNodeFilterProp="title"
          treeDefaultExpandAll
          placeholder={f.placeholder}
          disabled={f.disabled}
        />
      )
    default:
      return <Input placeholder={f.placeholder} disabled={f.disabled} />
  }
}
