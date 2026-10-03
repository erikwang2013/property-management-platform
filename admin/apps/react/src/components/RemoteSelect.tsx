// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState } from 'react'
import { Select } from 'antd'
import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import { readPage } from '../api/paging'

export interface RemoteSelectProps {
  endpoint: string
  queryKey: string
  searchParam?: string
  toOption: (row: Record<string, unknown>) => { label: string; value: number | string }
  extraParams?: Record<string, unknown>
  value?: string
  onChange?: (value: string | undefined) => void
  placeholder?: string
  allowClear?: boolean
}

/** 远程搜索下拉：表格/表单里选账单、房产、业主等大数据量对象时用 */
export default function RemoteSelect({
  endpoint,
  queryKey,
  searchParam = 'keyword',
  toOption,
  extraParams,
  value,
  onChange,
  placeholder,
  allowClear = true,
}: RemoteSelectProps) {
  const [term, setTerm] = useState('')
  const { data, isFetching } = useQuery({
    queryKey: [queryKey, term, extraParams],
    queryFn: async () =>
      readPage<Record<string, unknown>>(
        await api.get<unknown>(endpoint, { page_size: 20, [searchParam]: term, ...extraParams }),
      ),
  })

  return (
    <Select
      showSearch
      allowClear={allowClear}
      placeholder={placeholder}
      value={value}
      loading={isFetching}
      filterOption={false}
      onSearch={setTerm}
      onChange={(v) => onChange?.(v as string | undefined)}
      options={(data?.rows ?? []).map(toOption)}
    />
  )
}
