// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 用户管理：手工分页形状（getManualPage）+ 批量启禁用 + 弹窗表单。
// 列表 phone/email 是脱敏值，编辑前必须取详情，否则保存会把 `138****8000` 写回库。
import { Component, computed, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMessageService } from 'ng-zorro-antd/message';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { ENABLE, ENABLE_TAGS, options } from '../../api/dict';
import { Query } from '../../api/types';
import { ConfirmService } from '../../components/confirm.service';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FormField, FormValue, RowAction } from '../../components/types';

interface UserRow extends Record<string, unknown> {
  id: string;
  username: string;
  real_name: string;
  avatar: string;
  email: string;
  phone: string;
  status: number;
  tenant_id: number;
  last_login_at: string | null;
  last_login_ip: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

@Component({
  selector: 'xz-users',
  imports: [DataTableComponent, FormModalComponent, NzButtonModule, NzIconModule],
  templateUrl: './users.html',
})
export class UsersComponent {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  private readonly message = inject(NzMessageService);

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<FormValue | null>(null);
  protected readonly refresh = signal(0);
  /** 勾选行的 id，与 <xz-data-table> 的 [(selected)] 双向绑定 */
  protected readonly selected = signal<string[]>([]);

  protected readonly columns: Column[] = [
    { key: 'username', title: '用户名', width: '140px', kind: 'strong' },
    { key: 'real_name', title: '姓名', width: '120px' },
    // 后端 index() 对 phone/email 做了脱敏（139****0001 / a***@x.com），列名照 React 写明
    { key: 'phone', title: '手机号（脱敏）', width: '140px' },
    { key: 'email', title: '邮箱（脱敏）', width: '180px' },
    { key: 'status', title: '状态', width: '90px', kind: 'tag', map: ENABLE_TAGS },
    { key: 'last_login_at', title: '最近登录', width: '150px', kind: 'datetime' },
    { key: 'created_at', title: '创建时间', width: '150px', kind: 'datetime' },
  ];

  protected readonly filters = [
    { key: 'keyword', label: '用户名/姓名', placeholder: '输入用户名或姓名搜索' },
    { key: 'status', label: '状态', kind: 'select' as const, options: () => options(ENABLE) },
  ];

  protected readonly rowActions: RowAction<UserRow>[] = [
    { label: '编辑', run: (row) => this.edit(row) },
    { label: '删除', danger: true, run: (row) => this.remove(row) },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getManualPage<UserRow>(API.user, query, page, size);

  /** 创建/编辑共用（真实姓名起）：用户名与密码在编辑态规则不同 */
  private readonly tailFields: FormField[] = [
    { key: 'real_name', label: '真实姓名', required: true, hint: '最多 50 个字符' },
    { key: 'phone', label: '手机号' },
    { key: 'email', label: '邮箱' },
    { key: 'status', label: '状态', kind: 'select', options: () => options(ENABLE) },
  ];

  private readonly createFields: FormField[] = [
    { key: 'username', label: '用户名', required: true, hint: '3-50 个字符' },
    { key: 'password', label: '密码', kind: 'password', required: true, hint: '6-32 个字符' },
    ...this.tailFields,
  ];

  private readonly editFields: FormField[] = [
    { key: 'username', label: '用户名', immutable: true, hint: '用户名不可修改' },
    { key: 'password', label: '新密码', kind: 'password', hint: '留空则不修改' },
    ...this.tailFields,
  ];

  protected readonly fields = computed<FormField[]>(() =>
    this.editing() ? this.editFields : this.createFields,
  );

  private async edit(row: UserRow): Promise<void> {
    // 列表是脱敏数据，编辑前取详情补全明文手机号/邮箱
    const detail = await firstValueFrom(this.api.get<FormValue>(`${API.user}/${row.id}`));
    this.editing.set(detail);
    this.formOpen.set(true);
  }

  private async remove(row: UserRow): Promise<void> {
    const password = await this.confirm.askPassword(`确认删除用户「${row.username}」？`);
    if (!password) return;
    await firstValueFrom(this.api.delete(`${API.user}/${row.id}`, { password }));
    this.refresh.update((v) => v + 1);
  }

  protected create(): void {
    this.editing.set(null);
    this.formOpen.set(true);
  }

  protected async batchStatus(status: 0 | 1): Promise<void> {
    const ids = this.selected();
    if (!ids.length) {
      this.message.warning('请先选择用户');
      return;
    }
    try {
      // 批量启禁用不需要密码确认
      await firstValueFrom(this.api.post(API.userBatchStatus, { ids, status }));
      this.message.success(status === 1 ? '批量启用成功' : '批量禁用成功');
      this.selected.set([]);
      this.refresh.update((v) => v + 1);
    } catch (err) {
      this.message.error(errorText(err));
    }
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> => {
    const editing = this.editing();
    const payload: FormValue = { ...value };
    // status 空串会被后端 (int) 成 0（新建静默变禁用），删掉走后端默认 1=启用
    if (payload['status'] === '') delete payload['status'];
    if (editing) {
      // 密码留空 = 不修改；username 后端本就忽略，可原样带上
      if (!payload['password']) delete payload['password'];
      return firstValueFrom(this.api.put(`${API.user}/${editing['id']}`, payload));
    }
    return firstValueFrom(this.api.post(API.user, payload));
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };
}
