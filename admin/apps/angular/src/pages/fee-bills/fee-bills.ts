// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 账单管理：单张 CRUD + 按楼栋批量生成（POST /admin/fee-bill/batch/generate）。
// 批量生成的入参是 building_id（后端 batchGenerate 只认楼栋），楼栋下拉带小区前缀。
import { Component, computed, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMessageService } from 'ng-zorro-antd/message';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { BILL_STATUS, BILL_STATUS_TAGS, options } from '../../api/dict';
import { EMPTY_TREE_INDEX, indexRoomTree, TreeNode, TreeIndex } from '../../api/room-tree';
import { Option, Query } from '../../api/types';
import { ConfirmService } from '../../components/confirm.service';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FormField, FormValue, RowAction } from '../../components/types';

interface BillRow extends Record<string, unknown> {
  id: string;
  room_id: string;
  owner_id: string;
  fee_type_id: string;
  bill_number: string;
  amount: number;
  paid_amount: number;
  late_fee: number;
  start_date: string;
  end_date: string;
  due_date: string;
  status: number;
  paid_at: string;
  created_at: string;
}

interface RefRow {
  id: string;
  name: string;
  community_id?: string;
}

interface BatchResult {
  created: number;
  skipped: number;
}

@Component({
  selector: 'xz-fee-bills',
  imports: [DataTableComponent, FormModalComponent, NzButtonModule, NzIconModule],
  templateUrl: './fee-bills.html',
})
export class FeeBillsComponent {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  private readonly message = inject(NzMessageService);

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<FormValue | null>(null);
  protected readonly refresh = signal(0);

  /** 房产树索引：「房产」列只回 room_id，取一次树建映射（与 React 的 tree.roomName 同源） */
  private readonly treeIndex = signal<TreeIndex>(EMPTY_TREE_INDEX);

  protected readonly batchOpen = signal(false);

  // 下拉数据源
  private readonly feeTypes = signal<RefRow[]>([]);
  private readonly buildings = signal<RefRow[]>([]);
  private readonly communities = signal<RefRow[]>([]);
  private readonly roomTypes = signal<RefRow[]>([]);

  /** 列集为两端并集（team-lead 2026-10-03）：房产/费用类型/费用周期来自 React，「缴费时间」为本端独有 */
  protected readonly columns: Column[] = [
    { key: 'bill_number', title: '账单编号', kind: 'strong', width: '190px' },
    // 只回 hashid，用已拉的房产树与费用类型名册换名（与 React 侧 tree.roomName / feeTypes.nameOf 同源）；
    // 查不到回落 hashid，两端同口径
    { key: 'room_id', title: '房产', width: '150px', lookup: (v) => this.treeIndex().rooms.get(v) },
    { key: 'fee_type_id', title: '费用类型', width: '120px', lookup: (v) => this.feeTypeName(v) },
    { key: 'amount', title: '金额', width: '120px', align: 'right', kind: 'money' },
    { key: 'paid_amount', title: '已缴', width: '120px', align: 'right', kind: 'money' },
    // 文案以 docs/install.sql:764 的列注释为准（「滞纳金」），不再用「违约金」
    { key: 'late_fee', title: '滞纳金', width: '110px', align: 'right', kind: 'money' },
    // 起止合成一格（React 同句 `起 ~ 止`）：两列并排只是各占 120px 白位，信息完全重合
    {
      key: 'start_date',
      title: '费用周期',
      width: '180px',
      render: (row) => `${row['start_date'] || '—'} ~ ${row['end_date'] || '—'}`,
    },
    { key: 'due_date', title: '截止日期', width: '120px' },
    { key: 'status', title: '状态', width: '100px', kind: 'tag', map: BILL_STATUS_TAGS },
    { key: 'paid_at', title: '缴费时间', width: '150px' },
    { key: 'created_at', title: '创建时间', width: '150px' },
  ];

  protected readonly filters = [
    { key: 'keyword', label: '账单编号', placeholder: '输入账单编号搜索' },
    { key: 'status', label: '状态', kind: 'select' as const, options: () => options(BILL_STATUS) },
    { key: 'fee_type_id', label: '费用类型', kind: 'select' as const, options: () => this.feeTypeOptions() },
  ];

  /** 新建：选房产 + 费用类型 + 金额 + 周期；编辑：只允许改金额/滞纳金/周期/状态/备注 */
  protected readonly createFields: FormField[] = [
    { key: 'room_id', label: '房产', required: true, placeholder: '输入房号后从下拉选择', options: () => this.roomOptions() },
    { key: 'fee_type_id', label: '费用类型', kind: 'select', required: true, options: () => this.feeTypeOptions() },
    { key: 'amount', label: '账单金额(元)', kind: 'number', required: true, min: 0, step: 0.01 },
    { key: 'owner_id', label: '业主', kind: 'select', options: () => this.ownerOptions(), hint: '留空则 owner_id 落 0，建议与房产关联的业主保持一致' },
    { key: 'start_date', label: '费用周期起', kind: 'date', required: true },
    { key: 'end_date', label: '费用周期止', kind: 'date', required: true },
    { key: 'due_date', label: '缴费截止日', kind: 'date' },
    { key: 'remark', label: '备注', kind: 'textarea' },
  ];

  protected readonly editFields: FormField[] = [
    { key: 'amount', label: '账单金额(元)', kind: 'number', required: true, min: 0, step: 0.01 },
    { key: 'late_fee', label: '滞纳金(元)', kind: 'number', min: 0, step: 0.01 },
    { key: 'status', label: '状态', kind: 'select', options: () => options(BILL_STATUS) },
    { key: 'start_date', label: '费用周期起', kind: 'date' },
    { key: 'end_date', label: '费用周期止', kind: 'date' },
    { key: 'due_date', label: '缴费截止日', kind: 'date' },
    { key: 'remark', label: '备注', kind: 'textarea' },
  ];

  protected readonly batchFields: FormField[] = [
    { key: 'building_id', label: '楼栋', kind: 'select', required: true, options: () => this.buildingOptions(), hint: '按楼栋下全部房产生成，同房产同周期同费用类型不重复生成' },
    { key: 'fee_type_id', label: '费用类型', kind: 'select', required: true, options: () => this.feeTypeOptions() },
    { key: 'room_type_id', label: '限定户型', kind: 'select', options: () => this.roomTypeOptions(), hint: '留空 = 该楼栋全部房产' },
    { key: 'start_date', label: '费用周期起', kind: 'date', required: true },
    { key: 'end_date', label: '费用周期止', kind: 'date', required: true },
    { key: 'due_date', label: '缴费截止日', kind: 'date', hint: '留空 = 与周期止同日' },
    { key: 'amount', label: '固定金额(元)', kind: 'number', min: 0, step: 0.01, hint: '留空 = 按费用类型单价计算（面积计费类型会乘总面积）' },
  ];

  protected readonly fields = computed(() => (this.editing() ? this.editFields : this.createFields));

  protected readonly rowActions: RowAction<BillRow>[] = [
    { label: '编辑', run: (row) => this.edit(row) },
    { label: '删除', danger: true, run: (row) => this.remove(row) },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getPage<BillRow>(API.feeBill, query, page, size);

  constructor() {
    void this.loadRefs();
    // 拉不到只是「房产」列回落显示 hashid，不打断列表
    this.api.get<TreeNode[]>(API.roomTree).subscribe({
      next: (nodes) => this.treeIndex.set(indexRoomTree(nodes)),
      error: () => void 0,
    });
  }

  /** 费用类型 id → 名称；查不到回落 hashid（与 React 侧 `nameOf(id) || id` 同义） */
  private feeTypeName(id: string): string | undefined {
    return this.feeTypes().find((f) => f.id === id)?.name;
  }

  private async loadRefs(): Promise<void> {
    try {
      const [feeTypes, buildings, communities, roomTypes] = await Promise.all([
        firstValueFrom(this.api.getPage<RefRow>(API.feeType, {}, 1, 200)),
        firstValueFrom(this.api.getPage<RefRow>(API.building, {}, 1, 200)),
        firstValueFrom(this.api.getPage<RefRow>(API.community, {}, 1, 200)),
        firstValueFrom(this.api.getPage<RefRow>(API.roomType, {}, 1, 200)),
      ]);
      this.feeTypes.set(feeTypes.rows);
      this.buildings.set(buildings.rows);
      this.communities.set(communities.rows);
      this.roomTypes.set(roomTypes.rows);
    } catch (err) {
      this.message.error(`下拉数据加载失败：${errorText(err)}`);
    }
  }

  protected feeTypeOptions(): Option[] {
    return this.feeTypes().map((f) => ({ label: f.name, value: f.id }));
  }

  /** 楼栋标签带小区前缀，避免不同小区同名楼栋混淆 */
  protected buildingOptions(): Option[] {
    return this.buildings().map((b) => {
      const community = this.communities().find((c) => c.id === b.community_id);
      return { label: community ? `${community.name} / ${b.name}` : b.name, value: b.id };
    });
  }

  protected roomTypeOptions(): Option[] {
    return this.roomTypes().map((t) => ({ label: t.name, value: t.id }));
  }

  /** ponytail: 房产/业主下拉各取前 200 条，超过规模应换成带关键字搜索的远程下拉 */
  protected roomOptions(): Option[] {
    return this.rooms().map((r) => ({ label: r.name, value: r.id }));
  }

  protected ownerOptions(): Option[] {
    return this.owners().map((o) => ({ label: o.name, value: o.id }));
  }

  private readonly rooms = signal<RefRow[]>([]);
  private readonly owners = signal<RefRow[]>([]);
  private pickersLoaded = false;

  /** 首次打开新建表单时再拉房产/业主，避免进页面就发大请求 */
  private ensurePickers(): void {
    if (this.pickersLoaded) return;
    this.pickersLoaded = true;
    this.api.getPage<RefRow>(API.room, {}, 1, 200).subscribe({
      next: (page) => this.rooms.set(page.rows),
      error: (err: unknown) => {
        this.pickersLoaded = false;
        this.message.error(`房产列表加载失败：${errorText(err)}`);
      },
    });
    this.api.getPage<RefRow>(API.owner, {}, 1, 200).subscribe({
      next: (page) => this.owners.set(page.rows),
      error: () => this.owners.set([]),
    });
  }

  protected create(): void {
    this.editing.set(null);
    this.ensurePickers();
    this.formOpen.set(true);
  }

  private async edit(row: BillRow): Promise<void> {
    const detail = await firstValueFrom(this.api.get<FormValue>(`${API.feeBill}/${row.id}`));
    this.editing.set(detail);
    this.formOpen.set(true);
  }

  private async remove(row: BillRow): Promise<void> {
    const password = await this.confirm.askPassword(`确认删除账单「${row.bill_number}」？`);
    if (!password) return;
    await firstValueFrom(this.api.delete(`${API.feeBill}/${row.id}`, { password }));
    this.refresh.update((v) => v + 1);
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> => {
    const editing = this.editing();
    if (editing) {
      return firstValueFrom(this.api.put(`${API.feeBill}/${editing['id']}`, value));
    }
    // owner_id 为空时不下发，交给后端按房产关联业主补齐
    const body = { ...value };
    if (!body['owner_id']) delete body['owner_id'];
    return firstValueFrom(this.api.post(API.feeBill, body));
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };

  // —— 批量生成 ——

  protected openBatch(): void {
    this.batchOpen.set(true);
  }

  protected readonly submitBatch = async (value: FormValue): Promise<unknown> => {
    // 金额与截止日留空时不下发，让后端走「按单价计算 / 默认取周期止」两条分支
    const body = { ...value };
    for (const key of ['amount', 'due_date', 'room_type_id']) {
      if (!body[key]) delete body[key];
    }
    return firstValueFrom(this.api.post<BatchResult>(API.feeBillBatchGenerate, body));
  };

  protected readonly onBatchSaved = (result: unknown): void => {
    const r = result as BatchResult;
    this.message.success(`批量生成完成：新建 ${r?.created ?? 0} 张，跳过 ${r?.skipped ?? 0} 张（已存在同周期账单）`);
    this.refresh.update((v) => v + 1);
  };
}
