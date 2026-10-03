// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useQuery } from '@tanstack/react-query'
import { api } from './client'
import { EP } from './endpoints'
import { readPage } from './paging'
import type { TreeOption } from '../components/FormModal'
import type { Community, FeeType, Owner, Permission, TreeCommunity } from './types'

/** 选项型查询：一次抓一页（200 条），列表页的下拉数据量足够 */
function useOptions<T>(queryKey: readonly unknown[], path: string, params: Record<string, unknown> = {}) {
  return useQuery({
    queryKey: [...queryKey],
    queryFn: async () => readPage<T>(await api.get<unknown>(path, { page_size: 200, ...params })),
    staleTime: 5 * 60_000,
  })
}

export function useCommunities() {
  const query = useOptions<Community>(['lookup', 'communities'], EP.community)
  return {
    ...query,
    options: (query.data?.rows ?? []).map((c) => ({ label: c.name, value: c.id })),
  }
}

/** 小区→楼栋→单元→房产 四级树：列表取名与级联表单都用它 */
export function useRoomTree() {
  const query = useQuery({
    queryKey: ['lookup', 'room-tree'],
    queryFn: () => api.get<TreeCommunity[]>(EP.roomTree),
    staleTime: 5 * 60_000,
  })

  const communityName = new Map<string, string>()
  const buildingName = new Map<string, string>()
  const unitName = new Map<string, string>()
  const buildingsOf = new Map<string, { label: string; value: string }[]>()
  const unitsOf = new Map<string, { label: string; value: string }[]>()
  const roomsOf = new Map<string, { label: string; value: string }[]>()

  for (const community of query.data ?? []) {
    communityName.set(community.id, community.name)
    buildingsOf.set(
      community.id,
      community.children.map((b) => ({ label: b.name, value: b.id })),
    )
    for (const building of community.children) {
      buildingName.set(building.id, building.name)
      unitsOf.set(
        building.id,
        building.children.map((u) => ({ label: u.name, value: u.id })),
      )
      for (const unit of building.children) {
        unitName.set(unit.id, unit.name)
        roomsOf.set(
          unit.id,
          unit.children.map((r) => ({ label: r.name, value: r.id })),
        )
      }
    }
  }

  return {
    ...query,
    tree: query.data ?? [],
    communityName,
    buildingName,
    unitName,
    buildingsOf,
    unitsOf,
    roomsOf,
    roomName: (id: string) => {
      for (const rooms of roomsOf.values()) {
        const hit = rooms.find((r) => r.value === id)
        if (hit) return hit.label
      }
      return ''
    },
  }
}

export function useFeeTypes() {
  const query = useOptions<FeeType>(['lookup', 'fee-types'], EP.feeType)
  return {
    ...query,
    options: (query.data?.rows ?? []).map((f) => ({ label: f.name, value: f.id })),
    nameOf: (id: string) => query.data?.rows.find((f) => f.id === id)?.name ?? '',
  }
}

export function useOwners() {
  const query = useOptions<Owner>(['lookup', 'owners'], EP.owner)
  return {
    ...query,
    options: (query.data?.rows ?? []).map((o) => ({ label: `${o.name} ${o.phone}`, value: o.id })),
    nameOf: (id: string) => query.data?.rows.find((o) => o.id === id)?.name ?? '',
  }
}

/**
 * 维修人员名册：派单/改派表单的选项来源（`id` 是 hashid，`/admin/repair/{id}/assign` 收的就是它）。
 * 原「assign 收数字 ID、名册回 hashid 无法互转」的契约缺口，后端已于 2026-10-03 统一为 hashid。
 */
export function useStaffRoster() {
  return useOptions<{ id: string; name: string; job_title: string; status: number }>(['lookup', 'staff'], EP.staff)
}

export function usePermissions() {
  const query = useQuery({
    queryKey: ['lookup', 'permissions'],
    queryFn: () => api.get<Permission[]>(EP.permission),
    staleTime: 5 * 60_000,
  })
  const toTree = (nodes: Permission[]): TreeOption[] =>
    nodes.map((n) => ({
      title: `${n.name}（${n.slug}）`,
      value: n.id,
      children: n.children ? toTree(n.children) : undefined,
    }))
  return { ...query, treeData: toTree(query.data ?? []) }
}
