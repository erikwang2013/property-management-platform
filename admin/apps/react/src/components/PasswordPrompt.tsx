// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { Alert, Input, Modal, Typography } from 'antd'

export interface PasswordPromptProps {
  open: boolean
  title: string
  hint?: string
  onCancel: () => void
  onOk: (password: string) => Promise<void>
}

/** 敏感操作（删除等）的密码二次确认 —— 后端 confirmPassword 要求 */
export default function PasswordPrompt({ open, title, hint, onCancel, onOk }: PasswordPromptProps) {
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const close = () => {
    setPassword('')
    setError(null)
    onCancel()
  }

  const confirm = async () => {
    setLoading(true)
    setError(null)
    try {
      await onOk(password)
      close()
    } catch (err) {
      setError(err instanceof Error ? err.message : '操作失败')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal
      open={open}
      title={title}
      okText="确认"
      cancelText="取消"
      confirmLoading={loading}
      onCancel={close}
      onOk={() => void confirm()}
      okButtonProps={{ danger: true }}
    >
      <Typography.Paragraph type="secondary" style={{ marginTop: 8 }}>
        {hint ?? '该操作不可撤销，请输入当前登录密码确认。'}
      </Typography.Paragraph>
      {error && <Alert type="error" showIcon title={error} style={{ marginBottom: 12 }} />}
      <Input.Password
        placeholder="登录密码"
        value={password}
        autoFocus
        onChange={(e) => setPassword(e.target.value)}
        onPressEnter={() => void confirm()}
      />
    </Modal>
  )
}
