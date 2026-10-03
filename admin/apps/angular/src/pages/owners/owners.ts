// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 业主管理：搜索 + 分页 + 批量删除（密码确认）+ 弹窗表单。
// 列表 phone/email 为脱敏值，编辑前必须取详情，否则保存会把 `138****8000` 写回库。
import { Component, computed, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMessageService } from 'ng-zorro-antd/message';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { GENDER, OWNER_STATUS, OWNER_STATUS_TAGS, options } from '../../api/dict';
import { Query } from '../../api/types';
import { ConfirmService } from '../../components/confirm.service';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FormField, FormValue, RowAction } from '../../components/types';

interface OwnerRow extends Record<string, unknown> {
  id: string;
  name: string;
  phone: string;
  email: string;
  gender: number;
  status: number;
  check_in_date: string;
  created_at: string;
}

@Component({
  selector: 'xz-owners',
  imports: [DataTableComponent, FormModalComponent, NzButtonModule, NzIconModule],
  templateUrl: './owners.html',
})
export class OwnersComponent {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  private readonly message = inject(NzMessageService);

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<FormValue | null>(null);
  protected readonly refresh = signal(0);
  /** 勾选行的 id，与 <xz-data-table> 的 [(selected)] 双向绑定 */
  protected readonly selected = signal<string[]>([]);

  protected readonly columns: Column[] = [
    { key: 'name', title: '姓名', width: '120px', kind: 'strong' },
    // 后端 index() 对 phone/email 脱敏（maskPhone / maskEmail），列名照 React 写明
    { key: 'phone', title: '手机号（脱敏）', width: '140px' },
    { key: 'email', title: '邮箱（脱敏）', width: '180px' },
    // 属性值不是状态 → 纯文本（同 React 的 statusText）
    { key: 'gender', title: '性别', width: '80px', lookup: (v) => GENDER[Number(v)] ?? '—' },
    { key: 'check_in_date', title: '入住日期', width: '110px' },
    { key: 'status', title: '状态', width: '90px', kind: 'tag', map: OWNER_STATUS_TAGS },
    { key: 'created_at', title: '创建时间', width: '150px' },
  ];

  protected readonly filters = [
    { key: 'keyword', label: '姓名/手机号', placeholder: '输入姓名或手机号搜索' },
    { key: 'status', label: '状态', kind: 'select' as const, options: () => options(OWNER_STATUS) },
  ];

  protected readonly rowActions: RowAction<OwnerRow>[] = [
    { label: '编辑', run: (row) => this.edit(row) },
    { label: '删除', danger: true, run: (row) => this.remove(row) },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getPage<OwnerRow>(API.owner, query, page, size);

  /** 新增态不含状态（后端默认 1=入住），编辑态才追加 */
  private readonly baseFields: FormField[] = [
    { key: 'name', label: '姓名', required: true, placeholder: '如：张三' },
    { key: 'phone', label: '手机号', required: true, placeholder: '11 位手机号' },
    { key: 'email', label: '邮箱' },
    { key: 'gender', label: '性别', kind: 'select', options: () => options(GENDER) },
    { key: 'birthday', label: '生日', kind: 'date' },
    { key: 'emergency_contact', label: '紧急联系人' },
    { key: 'emergency_phone', label: '紧急联系电话' },
    { key: 'check_in_date', label: '入住日期', kind: 'date' },
    { key: 'remark', label: '备注', kind: 'textarea' },
  ];

  private readonly statusField: FormField = {
    key: 'status',
    label: '状态',
    kind: 'select',
    options: () => options(OWNER_STATUS),
  };

  protected readonly fields = computed<FormField[]>(() =>
    this.editing() ? [...this.baseFields, this.statusField] : this.baseFields,
  );

  private async edit(row: OwnerRow): Promise<void> {
    // 列表是脱敏数据，编辑前取详情补全明文手机号/邮箱
    const detail = await firstValueFrom(this.api.get<FormValue>(`${API.owner}/${row.id}`));
    this.editing.set(detail);
    this.formOpen.set(true);
  }

  private async remove(row: OwnerRow): Promise<void> {
    const password = await this.confirm.askPassword(`确认删除业主「${row.name}」？`);
    if (!password) return;
    await firstValueFrom(this.api.delete(`${API.owner}/${row.id}`, { password }));
    this.refresh.update((v) => v + 1);
  }

  protected create(): void {
    this.editing.set(null);
    this.formOpen.set(true);
  }

  protected async batchDestroy(): Promise<void> {
    const ids = this.selected();
    if (!ids.length) {
      this.message.warning('请先选择要删除的业主');
      return;
    }
    const password = await this.confirm.askPassword(`确认删除选中的 ${ids.length} 位业主？`);
    if (!password) return;
    try {
      await firstValueFrom(this.api.post(API.ownerBatchDestroy, { ids, password }));
      this.message.success('删除成功');
      this.selected.set([]);
      this.refresh.update((v) => v + 1);
    } catch (err) {
      this.message.error(errorText(err));
    }
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> => {
    const editing = this.editing();
    const payload: FormValue = { ...value };
    // 空串不能直接落库：gender 是 NOT NULL TINYINT（严格模式报错），删掉走库默认 0；
    // birthday/check_in_date 是可空 DATE，空串会 1292 报错，改 null 才能落库/清空
    if (payload['gender'] === '') delete payload['gender'];
    for (const key of ['birthday', 'check_in_date']) {
      if (payload[key] === '') payload[key] = null;
    }
    if (editing) {
      return firstValueFrom(this.api.put(`${API.owner}/${editing['id']}`, payload));
    }
    return firstValueFrom(this.api.post(API.owner, payload));
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };
}
