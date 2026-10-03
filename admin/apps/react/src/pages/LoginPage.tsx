// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useCallback, useEffect, useRef, useState } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { Alert, Button, Card, Flex, Form, Input, Spin, Tag, Typography } from 'antd'
import { LockOutlined, UserOutlined } from '@ant-design/icons'
import { api, decodeCaptchaImage, toOriginalCoords } from '../api/client'
import { EP } from '../api/endpoints'
import { useAuth, type AuthUser } from '../auth/store'
import { PetFull, petGreeting } from '../components/PetMark'
import { colors } from '../theme/tokens'

interface CaptchaText {
  text: string
  order: number
}

interface CaptchaState {
  key: string
  src: string
  texts: CaptchaText[]
  width: number
  height: number
}

interface LoginResponse {
  access_token: string
  refresh_token?: string
  user?: AuthUser
}

export default function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const setAuth = useAuth((s) => s.setAuth)
  const accessToken = useAuth((s) => s.accessToken)
  const [form] = Form.useForm<{ username: string; password: string }>()
  const [captcha, setCaptcha] = useState<CaptchaState | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const clicks = useRef<{ x: number; y: number }[]>([])
  const imgRef = useRef<HTMLImageElement>(null)
  const [clickCount, setClickCount] = useState(0)

  const loadCaptcha = useCallback(async () => {
    clicks.current = []
    setClickCount(0)
    try {
      const data = await api.post<{ key: string; image: string; extra: { texts: CaptchaText[] } }>(
        EP.captchaGenerate,
        { difficulty: 'medium' },
      )
      const src = decodeCaptchaImage(data.image)
      // 画布尺寸以实际返回为准（后端默认 300×200），点击时按渲染尺寸等比换算
      const size = await imageSize(src)
      setCaptcha({ key: data.key, src, texts: [...data.extra.texts].sort((a, b) => a.order - b.order), ...size })
    } catch (err) {
      setError(err instanceof Error ? err.message : '验证码加载失败')
    }
  }, [])

  useEffect(() => {
    void loadCaptcha()
  }, [loadCaptcha])

  if (accessToken) return <Navigate to="/dashboard" replace />

  const handleClick = (event: React.MouseEvent<HTMLImageElement>) => {
    if (!captcha) return
    const rect = event.currentTarget.getBoundingClientRect()
    const [x, y] = toOriginalCoords(
      { x: event.clientX - rect.left, y: event.clientY - rect.top },
      { width: captcha.width, height: captcha.height },
      { width: rect.width, height: rect.height },
    )
    clicks.current = [...clicks.current.slice(0, captcha.texts.length - 1), { x, y }]
    setClickCount(clicks.current.length)
  }

  const submit = async () => {
    if (!captcha) return
    // 同 FormModal：校验失败会 reject，调用处 `onFinish={() => void submit()}` 不接 promise（见其注释）
    const values = await form.validateFields().catch(() => null)
    if (!values) return
    if (clicks.current.length < captcha.texts.length) {
      setError('请按提示点完验证码上的文字')
      return
    }
    setLoading(true)
    setError(null)
    try {
      const data = await api.post<LoginResponse>(EP.login, {
        username: values.username,
        password: values.password,
        captcha_key: captcha.key,
        clicks: clicks.current,
      })
      setAuth(data)
      const from = (location.state as { from?: string } | null)?.from
      navigate(from && from !== '/login' ? from : '/dashboard', { replace: true })
    } catch (err) {
      setError(err instanceof Error ? err.message : '登录失败')
      form.setFieldValue('password', '')
      await loadCaptcha()
    } finally {
      setLoading(false)
    }
  }

  const hints = captcha?.texts ?? []

  return (
    <Flex style={{ minHeight: '100vh', background: colors.bgLayout }}>
      <Flex
        vertical
        align="center"
        justify="center"
        gap={16}
        style={{
          flex: '1 1 46%',
          background: `linear-gradient(160deg, ${colors.primaryLight} 0%, ${colors.primaryDark} 100%)`,
          padding: 40,
        }}
      >
        <PetFull height={160} />
        <Typography.Title level={3} style={{ color: '#fff', margin: 0 }}>
          物业管理平台
        </Typography.Title>
        <Card size="small" style={{ maxWidth: 320, background: 'rgba(255,255,255,.14)', border: 'none' }}>
          <Typography.Text style={{ color: '#fff' }}>
            {petGreeting()}！我是小筑，今天也帮您把小区管得妥妥的。
          </Typography.Text>
        </Card>
      </Flex>

      <Flex vertical align="center" justify="center" style={{ flex: '1 1 54%', padding: 24 }}>
        <Card style={{ width: 400, maxWidth: '100%' }} styles={{ body: { padding: 28 } }}>
          <Typography.Title level={4} style={{ marginTop: 0 }}>
            登录
          </Typography.Title>
          {error && <Alert type="error" showIcon title={error} style={{ marginBottom: 16 }} />}
          <Form form={form} layout="vertical" onFinish={() => void submit()}>
            <Form.Item name="username" label="用户名" rules={[{ required: true, message: '请输入用户名' }]}>
              <Input size="large" prefix={<UserOutlined />} placeholder="用户名" autoComplete="username" />
            </Form.Item>
            <Form.Item
              name="password"
              label="密码"
              rules={[
                { required: true, message: '请输入密码' },
                {
                  pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,32}$/,
                  message: '8-32 位，含大小写字母、数字与特殊字符 @$!%*?&',
                },
              ]}
            >
              <Input.Password size="large" prefix={<LockOutlined />} placeholder="密码" autoComplete="current-password" />
            </Form.Item>

            <Flex vertical gap={8} style={{ marginBottom: 16 }}>
              <Flex justify="space-between" align="center">
                <Typography.Text type="secondary">请依次点击验证码上的文字</Typography.Text>
                <Button type="link" size="small" onClick={() => void loadCaptcha()}>
                  换一张
                </Button>
              </Flex>
              {hints.length > 0 && (
                <Flex gap={8} wrap>
                  {hints.map((h, index) => (
                    /* 三态用语义 token：当前待点 warning、已点 success、未轮到 default。
                       原写 gold/green —— 那是 antd 的另一组色值（#FAAD14 / #52C41A），与 token 的
                       #F59E0B / #10B981 不同名不同值，两端各写一种就永远对不齐（Angular 同位置 hintTone() 即此三档） */
                    <Tag key={h.order} color={clickCount === index ? 'warning' : clickCount > index ? 'success' : 'default'}>
                      {index + 1}. {h.text}
                    </Tag>
                  ))}
                </Flex>
              )}
              <div style={{ position: 'relative', lineHeight: 0 }}>
                {captcha ? (
                  <>
                    <img
                      ref={imgRef}
                      src={captcha.src}
                      alt="点击验证码"
                      width="100%"
                      style={{ borderRadius: 8, cursor: 'crosshair', display: 'block' }}
                      onClick={handleClick}
                    />
                    {clicks.current.map((c, index) => (
                      <span
                        key={index}
                        style={{
                          position: 'absolute',
                          left: `${(c.x / captcha.width) * 100}%`,
                          top: `${(c.y / captcha.height) * 100}%`,
                          transform: 'translate(-50%, -50%)',
                          width: 22,
                          height: 22,
                          borderRadius: '50%',
                          background: colors.accent,
                          color: '#fff',
                          fontSize: 12,
                          lineHeight: '22px',
                          textAlign: 'center',
                          pointerEvents: 'none',
                        }}
                      >
                        {index + 1}
                      </span>
                    ))}
                  </>
                ) : (
                  <Flex align="center" justify="center" style={{ height: 160 }}>
                    <Spin />
                  </Flex>
                )}
              </div>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                已点击 {clickCount}/{hints.length || '-'}（点错可重新点击覆盖最后一步）
              </Typography.Text>
            </Flex>

            <Button type="primary" size="large" block htmlType="submit" loading={loading} disabled={!captcha}>
              登录
            </Button>
          </Form>
        </Card>
      </Flex>
    </Flex>
  )
}

/** 读取图片原始像素尺寸（用于点击坐标换算） */
function imageSize(src: string): Promise<{ width: number; height: number }> {
  return new Promise((resolve) => {
    const img = new Image()
    img.onload = () => resolve({ width: img.naturalWidth || 300, height: img.naturalHeight || 200 })
    img.onerror = () => resolve({ width: 300, height: 200 })
    img.src = src
  })
}
