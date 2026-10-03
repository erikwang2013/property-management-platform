// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// /admin/room/tree 的四层节点：小区 → 楼栋 → 单元 → 房产。
// 列表里只回 hashid 的关联列（报修的房产、账单的房产、房产页的小区/楼栋/单元）都靠它换可读名，
// 与 React 侧 `tree.roomName(id) || id` 同一份数据源。

export interface TreeNode {
  id: string;
  name: string;
  type: 'community' | 'building' | 'unit' | 'room';
  status?: number;
  children?: TreeNode[];
}

/** 各层 id → name。查不到时各页按 React 的口径回落（房产列回落 hashid，楼栋/单元列给「—」）。 */
export interface TreeIndex {
  communities: Map<string, string>;
  buildings: Map<string, string>;
  units: Map<string, string>;
  rooms: Map<string, string>;
}

/** 节点 type → 落哪个桶（'community' + 's' 拼不出 'communities'，只能显式写） */
const BUCKET: Record<TreeNode['type'], keyof TreeIndex> = {
  community: 'communities',
  building: 'buildings',
  unit: 'units',
  room: 'rooms',
};

export function indexRoomTree(nodes: TreeNode[] | null | undefined): TreeIndex {
  const index: TreeIndex = {
    communities: new Map(),
    buildings: new Map(),
    units: new Map(),
    rooms: new Map(),
  };
  const walk = (list: TreeNode[]): void => {
    for (const node of list) {
      index[BUCKET[node.type]].set(node.id, node.name);
      if (node.children?.length) walk(node.children);
    }
  };
  // 响应不是树数组时按「树没拉到」处理：三列回落显示 hashid，列表照常 —— 与各调用点
  // error 分支同一落点。**不能抛**：调用点是在 next 回调里调它，next 里抛出的异常越过订阅方
  // 自己的 error 回调直达全局错误处理（实测 console 只剩压缩后的 `t is not iterable`，
  // 页面看着正常、问题被吞掉）。调用点本来就有「拉不到不打断列表」的约定。
  walk(Array.isArray(nodes) ? nodes : []);
  return index;
}

export const EMPTY_TREE_INDEX: TreeIndex = indexRoomTree([]);
