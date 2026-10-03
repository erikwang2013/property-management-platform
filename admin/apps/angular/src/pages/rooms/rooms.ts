// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 房产管理：左侧小区→楼栋→单元→房产 层级树定位，右侧复用通用列表页做 CRUD。
// 树节点只负责把 community_id / building_id / unit_id 写进查询条件，分页逻辑仍在 data-table 里。
import { Component, computed, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzCardModule } from 'ng-zorro-antd/card';
import { NzEmptyModule } from 'ng-zorro-antd/empty';
import { NzGridModule } from 'ng-zorro-antd/grid';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzTreeModule, NzTreeNodeOptions } from 'ng-zorro-antd/tree';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import {
  DECORATION,
  options,
  ROOM_STATUS,
  ROOM_STATUS_TAGS,
  USAGE_TYPE,
} from '../../api/dict';
import { EMPTY_TREE_INDEX, indexRoomTree, TreeNode, TreeIndex } from '../../api/room-tree';
import { Option, Query } from '../../api/types';
import { ConfirmService } from '../../components/confirm.service';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FormField, FormValue, RowAction } from '../../components/types';

interface RoomRow extends Record<string, unknown> {
  id: string;
  community_id: string;
  building_id: string;
  unit_id: string;
  room_type_id: string;
  room_number: string;
  floor: number;
  area_indoor: number;
  area_total: number;
  orientation: string;
  usage_type: number;
  status: number;
  created_at: string;
}

/** 下拉数据源：楼栋 / 单元 / 户型 / 小区 */
interface RefRow {
  id: string;
  name: string;
  community_id?: string;
  building_id?: string;
}

/** 树侧栏选中的定位范围 */
interface Scope {
  community_id?: string;
  building_id?: string;
  unit_id?: string;
  label: string;
}

@Component({
  selector: 'xz-rooms',
  imports: [
    DataTableComponent,
    FormModalComponent,
    NzButtonModule,
    NzCardModule,
    NzEmptyModule,
    NzGridModule,
    NzIconModule,
    NzTreeModule,
  ],
  templateUrl: './rooms.html',
  styleUrl: './rooms.scss',
})
export class RoomsComponent {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  private readonly message = inject(NzMessageService);

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<FormValue | null>(null);
  protected readonly refresh = signal(0);

  protected readonly treeLoading = signal(false);
  protected readonly tree = signal<NzTreeNodeOptions[]>([]);
  /** 同一棵树建 id→name 索引，列表的 小区/楼栋/单元 三列用它把 hashid 换成名字（与 React 侧 tree.*Name 同源） */
  private readonly treeIndex = signal<TreeIndex>(EMPTY_TREE_INDEX);
  /** 当前定位范围；空 = 全部房产 */
  protected readonly scope = signal<Scope | null>(null);
  protected readonly scopeKey = computed(() => this.scope()?.label ?? '全部房产');

  // 下拉数据源（懒加载一次，供表单使用）
  private readonly communities = signal<RefRow[]>([]);
  private readonly buildings = signal<RefRow[]>([]);
  private readonly units = signal<RefRow[]>([]);
  private readonly roomTypes = signal<RefRow[]>([]);
  private refsLoaded = false;

  protected readonly columns: Column[] = [
    { key: 'room_number', title: '房号', kind: 'strong', width: '140px' },
    // 三列只回 hashid，靠 room/tree 的索引换名；查不到时的回落与 React 逐列一致：
    // 小区回落 hashid，楼栋/单元给「—」（这两个 id 缺失时显示一串 hashid 没有意义）
    { key: 'community_id', title: '小区', width: '150px', lookup: (v) => this.treeIndex().communities.get(v) || v },
    { key: 'building_id', title: '楼栋', width: '100px', lookup: (v) => this.treeIndex().buildings.get(v) || '—' },
    { key: 'unit_id', title: '单元', width: '100px', lookup: (v) => this.treeIndex().units.get(v) || '—' },
    { key: 'floor', title: '楼层', width: '80px', align: 'right' },
    { key: 'area_total', title: '总面积(m²)', width: '120px', align: 'right' },
    { key: 'area_indoor', title: '套内(m²)', width: '110px', align: 'right' },
    { key: 'orientation', title: '朝向', width: '90px' },
    // 属性值不是状态 → 纯文本（team-lead 2026-10-03 裁定：标签只用于有语义的状态，同 React 的 statusText）
    { key: 'usage_type', title: '用途', width: '100px', lookup: (v) => USAGE_TYPE[Number(v)] ?? '—' },
    { key: 'status', title: '状态', width: '100px', kind: 'tag', map: ROOM_STATUS_TAGS },
    { key: 'created_at', title: '创建时间', width: '150px' },
  ];

  protected readonly filters = [
    { key: 'keyword', label: '房号', placeholder: '输入房号搜索' },
    { key: 'status', label: '状态', kind: 'select' as const, options: () => options(ROOM_STATUS) },
  ];

  protected readonly fields: FormField[] = [
    { key: 'community_id', label: '所属小区', kind: 'select', required: true, options: () => this.communityOptions(), immutable: true },
    { key: 'building_id', label: '所属楼栋', kind: 'select', required: true, options: () => this.buildingOptions(), immutable: true },
    { key: 'unit_id', label: '所属单元', kind: 'select', required: true, options: () => this.unitOptions(), immutable: true },
    { key: 'room_number', label: '房号', required: true, placeholder: '如：1-1-101' },
    { key: 'floor', label: '楼层', kind: 'number', min: -3, max: 200 },
    { key: 'room_type_id', label: '户型', kind: 'select', options: () => this.roomTypeOptions() },
    { key: 'area_indoor', label: '套内面积(m²)', kind: 'number', min: 0, step: 0.01 },
    { key: 'area_shared', label: '公摊面积(m²)', kind: 'number', min: 0, step: 0.01 },
    { key: 'area_total', label: '总面积(m²)', kind: 'number', min: 0, step: 0.01 },
    { key: 'orientation', label: '朝向', placeholder: '如：南' },
    { key: 'decoration', label: '装修', kind: 'select', options: () => options(DECORATION) },
    { key: 'usage_type', label: '用途', kind: 'select', options: () => options(USAGE_TYPE) },
    { key: 'status', label: '状态', kind: 'select', options: () => options(ROOM_STATUS) },
    { key: 'remark', label: '备注', kind: 'textarea' },
  ];

  protected readonly rowActions: RowAction<RoomRow>[] = [
    { label: '编辑', run: (row) => this.edit(row) },
    { label: '删除', danger: true, run: (row) => this.remove(row) },
  ];

  /**
   * 树侧栏的范围合并进查询条件后交给通用列表页，分页/搜索仍是同一套实现。
   * ponytail: 依赖 refreshToken 触发重查，不再自建一套分页。
   */
  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getPage<RoomRow>(API.room, { ...query, ...this.scope() }, page, size);

  constructor() {
    void this.loadTree();
  }

  private async loadTree(): Promise<void> {
    this.treeLoading.set(true);
    try {
      const nodes = await firstValueFrom(this.api.get<TreeNode[]>(API.roomTree));
      this.treeIndex.set(indexRoomTree(nodes));
      this.tree.set(nodes.map((n) => this.toNode(n)));
    } catch (err) {
      this.message.error(errorText(err));
      this.tree.set([]);
      this.treeIndex.set(EMPTY_TREE_INDEX);
    } finally {
      this.treeLoading.set(false);
    }
  }

  /** 层级图标（已在 APP_ICONS 注册） */
  private static readonly NODE_ICON: Record<TreeNode['type'], string | undefined> = {
    community: 'home',
    building: 'apartment',
    unit: 'appstore',
    room: undefined,
  };

  /** 后端节点 → NG-ZORRO 节点（房产为叶子，不可再展开） */
  private toNode(node: TreeNode): NzTreeNodeOptions {
    return {
      title: node.name,
      key: `${node.type}:${node.id}`,
      isLeaf: node.type === 'room',
      expanded: node.type === 'community',
      icon: RoomsComponent.NODE_ICON[node.type],
      children: node.children?.map((c) => this.toNode(c)),
    };
  }

  protected onTreeSelect(keys: string[] | undefined): void {
    if (!keys?.length) {
      this.clearScope();
      return;
    }
    const [type, id] = keys[0].split(':');
    // 房产节点直接进编辑，避免与表头搜索框抢同一个 keyword 参数
    if (type === 'room') {
      void this.editById(id);
      return;
    }
    const label = this.titleOf(keys[0]);
    if (type === 'community') {
      this.scope.set({ community_id: id, label });
    } else if (type === 'building') {
      this.scope.set({ building_id: id, label });
    } else {
      this.scope.set({ unit_id: id, label });
    }
    this.refresh.update((v) => v + 1);
  }

  private async editById(id: string): Promise<void> {
    const detail = await firstValueFrom(this.api.get<FormValue>(`${API.room}/${id}`));
    await this.openForm(detail);
  }

  private titleOf(key: string): string {
    const stack = [...this.tree()];
    while (stack.length) {
      const node = stack.shift() as NzTreeNodeOptions;
      if (node.key === key) return String(node.title);
      if (node.children) stack.push(...node.children);
    }
    return '全部房产';
  }

  protected clearScope(): void {
    this.scope.set(null);
    this.refresh.update((v) => v + 1);
  }

  protected create(): void {
    void this.openForm(null);
  }

  private edit(row: RoomRow): Promise<void> {
    return this.editById(row.id);
  }

  /** 表单下拉需要全量小区/楼栋/单元/户型，打开弹窗前确保已加载 */
  private async openForm(value: FormValue | null): Promise<void> {
    this.editing.set(value);
    this.formOpen.set(true);
    if (this.refsLoaded) return;
    try {
      const [communities, buildings, units, roomTypes] = await Promise.all([
        firstValueFrom(this.api.getPage<RefRow>(API.community, {}, 1, 200)),
        firstValueFrom(this.api.getPage<RefRow>(API.building, {}, 1, 200)),
        firstValueFrom(this.api.getPage<RefRow>(API.unit, {}, 1, 200)),
        firstValueFrom(this.api.getPage<RefRow>(API.roomType, {}, 1, 200)),
      ]);
      this.communities.set(communities.rows);
      this.buildings.set(buildings.rows);
      this.units.set(units.rows);
      this.roomTypes.set(roomTypes.rows);
      this.refsLoaded = true;
    } catch (err) {
      this.message.error(`房产下拉数据加载失败：${errorText(err)}`);
    }
  }

  // —— 下拉项：用「父级 / 子级」全路径标签，避免通用弹窗做多级联动 ——

  protected communityOptions(): Option[] {
    return this.communities().map((c) => ({ label: c.name, value: c.id }));
  }

  protected buildingOptions(): Option[] {
    return this.buildings().map((b) => ({
      label: this.pathLabel(b.community_id, this.communities(), b.name),
      value: b.id,
    }));
  }

  protected unitOptions(): Option[] {
    return this.units().map((u) => ({
      label: this.pathLabel(u.building_id, this.buildings(), u.name),
      value: u.id,
    }));
  }

  protected roomTypeOptions(): Option[] {
    return this.roomTypes().map((t) => ({ label: t.name, value: t.id }));
  }

  /** 楼栋只带 community_id，路径退化为一级；单元带 building_id 可拼出二级 */
  private pathLabel(parentId: string | undefined, parents: RefRow[], name: string): string {
    const parent = parents.find((p) => p.id === parentId);
    return parent ? `${parent.name} / ${name}` : name;
  }

  private async remove(row: RoomRow): Promise<void> {
    const password = await this.confirm.askPassword(`确认删除房产「${row.room_number}」？`);
    if (!password) return;
    await firstValueFrom(this.api.delete(`${API.room}/${row.id}`, { password }));
    this.refresh.update((v) => v + 1);
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> => {
    const editing = this.editing();
    if (editing) {
      // 所属小区/楼栋/单元后端不可改，update 不接受这三个字段
      const { community_id: _c, building_id: _b, unit_id: _u, ...rest } = value;
      return firstValueFrom(this.api.put(`${API.room}/${editing['id']}`, rest));
    }
    return firstValueFrom(this.api.post(API.room, value));
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
    void this.loadTree();
  };
}
