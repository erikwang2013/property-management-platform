// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useEffect, useState } from 'react'
import { Navigate, Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  Avatar,
  Breadcrumb,
  Button,
  Drawer,
  Dropdown,
  Flex,
  Grid,
  Layout,
  Menu,
  Typography,
  theme as antdTheme,
} from 'antd'
import { LogoutOutlined, MenuFoldOutlined, MenuUnfoldOutlined, UserOutlined } from '@ant-design/icons'
import { useAuth } from '../auth/store'
import { api } from '../api/client'
import { EP } from '../api/endpoints'
import { PetMark } from '../components/PetMark'
import RouteErrorBoundary from '../components/RouteErrorBoundary'
import { colors, layout as sizes } from '../theme/tokens'
import { NAV_GROUPS, PAGE_TITLES } from './menu'

const menuItems = NAV_GROUPS.map((group) => ({
  type: 'group' as const,
  key: group.label,
  label: group.label,
  children: group.items.map((item) => ({ key: item.path, icon: item.icon, label: item.label })),
}))

export default function AppLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const screens = Grid.useBreakpoint()
  const { token } = antdTheme.useToken()
  const [collapsed, setCollapsed] = useState(false)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const accessToken = useAuth((s) => s.accessToken)
  const user = useAuth((s) => s.user)
  const clear = useAuth((s) => s.clear)

  const isDrawer = !screens.md
  // 未匹配到 PAGE_TITLES 的路径就是落进 `*` 通配的 404 页（路由表里其余路径都有标题）：
  // 标题也要写全 `<当前页> · 物业管理平台`，别只剩光杆系统名（同 Angular 的「页面不存在 · 物业管理平台」）
  const title = PAGE_TITLES[location.pathname] ?? '页面不存在'

  useEffect(() => {
    document.title = `${title} · 物业管理平台`
  }, [title])

  if (!accessToken) return <Navigate to="/login" replace state={{ from: location.pathname }} />

  const logout = async () => {
    try {
      await api.post(EP.profileLogout)
    } catch {
      // 登出失败也要清本地态
    }
    clear()
    navigate('/login', { replace: true })
  }

  const menu = (
    <Menu
      theme="dark"
      mode="inline"
      selectedKeys={[location.pathname]}
      items={menuItems}
      onClick={({ key }) => {
        navigate(key)
        setDrawerOpen(false)
      }}
      style={{ borderInlineEnd: 'none' }}
    />
  )

  const brand = (
    <Flex align="center" gap={8} style={{ height: sizes.headerHeight, padding: collapsed && !isDrawer ? 0 : '0 16px', justifyContent: collapsed && !isDrawer ? 'center' : 'flex-start' }}>
      <PetMark size={28} />
      {(!collapsed || isDrawer) && <Typography.Text strong style={{ color: '#fff', fontSize: 15 }}>物业管理平台</Typography.Text>}
    </Flex>
  )

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {isDrawer ? (
        <Drawer
          open={drawerOpen}
          onClose={() => setDrawerOpen(false)}
          placement="left"
          // antd 6：width 已废弃，size 直接收数值（等价，DrawerPanel 拿到的都是同一个数字）
          size={sizes.siderWidth}
          styles={{ body: { padding: 0, background: colors.siderBg }, header: { display: 'none' } }}
        >
          {brand}
          {menu}
        </Drawer>
      ) : (
        <Layout.Sider
          theme="dark"
          width={sizes.siderWidth}
          collapsedWidth={sizes.siderCollapsedWidth}
          collapsed={collapsed}
          breakpoint="lg"
          onBreakpoint={(broken) => setCollapsed(broken)}
        >
          {brand}
          {menu}
        </Layout.Sider>
      )}

      <Layout>
        <Layout.Header
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '0 16px',
            borderBottom: `1px solid ${token.colorBorderSecondary}`,
          }}
        >
          <Flex align="center" gap={12}>
            <Button
              type="text"
              aria-label="切换菜单"
              icon={isDrawer || collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
              onClick={() => (isDrawer ? setDrawerOpen(true) : setCollapsed(!collapsed))}
            />
            <Breadcrumb items={[{ title: '物业管理平台' }, { title: title || '页面' }]} />
          </Flex>
          <Dropdown
            menu={{
              items: [
                { key: 'profile', icon: <UserOutlined />, label: '个人中心' },
                { type: 'divider' },
                { key: 'logout', icon: <LogoutOutlined />, label: '退出登录', danger: true },
              ],
              onClick: ({ key }) => (key === 'logout' ? void logout() : navigate('/system/profile')),
            }}
          >
            <Flex align="center" gap={8} style={{ cursor: 'pointer' }}>
              <Avatar size={28} style={{ background: colors.primary }} icon={<UserOutlined />} />
              <Typography.Text>{user?.real_name || user?.username || '管理员'}</Typography.Text>
            </Flex>
          </Dropdown>
        </Layout.Header>

        <Layout.Content style={{ padding: sizes.contentPadding, background: colors.bgLayout }}>
          {/* 路由级错误边界：页面崩了只替换内容区，侧栏/顶栏留着（换路由即复位） */}
          <RouteErrorBoundary resetKey={location.pathname}>
            <Outlet />
          </RouteErrorBoundary>
        </Layout.Content>
      </Layout>
    </Layout>
  )
}
