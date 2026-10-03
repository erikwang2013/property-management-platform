// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useNavigate } from 'react-router-dom'
import { Button, Card, Flex, Result, Typography } from 'antd'
import { PetFull } from '../components/PetMark'

export default function NotFoundPage() {
  const navigate = useNavigate()

  return (
    <Card>
      <Flex vertical align="center" gap={8} style={{ padding: '32px 0' }}>
        <PetFull height={140} />
        <Result
          status="404"
          title="404"
          subTitle="小筑翻了半天也没找到这个页面。"
          extra={
            <Button type="primary" onClick={() => navigate('/dashboard')}>
              返回值班台
            </Button>
          }
        />
        <Typography.Text type="secondary">物业管理平台 · 小筑随时待命</Typography.Text>
      </Flex>
    </Card>
  )
}
