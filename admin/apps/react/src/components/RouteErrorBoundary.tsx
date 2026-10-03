// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { Component, useState, type ReactNode } from 'react'
import { Button, Flex, Typography } from 'antd'
import { useQueryClient } from '@tanstack/react-query'
import { PetFull } from './PetMark'
import { colors } from '../theme/tokens'

interface BoundaryProps {
  children: ReactNode
  retrying: boolean
  onRetry: () => void
}

interface BoundaryState {
  error: Error | null
}

/**
 * 路由级错误边界：某个页面渲染抛错时只把**内容区**换成回退界面，侧栏/顶栏照常可用（能切走）。
 * 不用 antd 的裸报错页 —— 回退界面按 §2 用小筑形象 + 说明 + 重试。
 * ponytail: 只在 class 组件里 React 才认 `getDerivedStateFromError`，故这里必须留一个 class。
 */
class Boundary extends Component<BoundaryProps, BoundaryState> {
  state: BoundaryState = { error: null }

  static getDerivedStateFromError(error: Error): BoundaryState {
    return { error }
  }

  render() {
    const { error } = this.state
    if (!error) return this.props.children
    return (
      <Flex vertical align="center" justify="center" gap={12} style={{ padding: '48px 16px', textAlign: 'center' }}>
        <PetFull height={120} />
        <Typography.Title level={4} style={{ margin: 0 }}>
          这个页面出了点问题
        </Typography.Title>
        <Typography.Text style={{ color: colors.textSecondary }}>
          页面渲染时抛了错：{error.message || '未知错误'}。
        </Typography.Text>
        <Typography.Text style={{ color: colors.textSecondary }}>
          左侧导航仍然可用，可以直接切到别的页面；也可以重试这一步。
        </Typography.Text>
        <Button type="primary" loading={this.props.retrying} onClick={this.props.onRetry}>
          重试
        </Button>
      </Flex>
    )
  }
}

/**
 * 边界挂在路由内容区（`AppLayout` 的 `<Outlet />` 外层），不是 `main.tsx` 最外层 ——
 * 后者一崩整壳消失，连侧栏都没了。
 *
 * 复位有两路：① 换路由（`resetKey` 变）；② 点「重试」。两者都用 `key` 重建边界与其子树，
 * 让页面按新的查询结果重新渲染一遍。
 *
 * 「重试」为什么要 `refetchQueries` 而不是 `invalidateQueries`：崩掉的子树在**渲染期**就抛错了，
 * 没走到提交，React Query 也就没来得及订阅（订阅在 effect 里）—— 此时缓存里没有订阅者，
 * `invalidateQueries` 只标脏不发请求，重建子树仍是同一份坏数据。所以要显式重发一次缓存里的查询
 * （`type: 'all'` 才包含已无订阅者的那些），发完再重建子树：好数据则页面自己恢复，坏数据则再落到回退界面。
 */
export default function RouteErrorBoundary({ resetKey, children }: { resetKey: string; children: ReactNode }) {
  const queryClient = useQueryClient()
  const [attempt, setAttempt] = useState(0)
  const [retrying, setRetrying] = useState(false)
  return (
    <Boundary
      key={`${resetKey}#${attempt}`}
      retrying={retrying}
      onRetry={() => {
        setRetrying(true)
        void queryClient.refetchQueries({ type: 'all' }).finally(() => {
          setRetrying(false)
          setAttempt((n) => n + 1)
        })
      }}
    >
      {children}
    </Boundary>
  )
}
