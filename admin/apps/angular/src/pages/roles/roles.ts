// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 角色权限：角色 CRUD（分页形状 B：page + limit）+ 权限树勾选。
// 注意：后端 RoleController 无 show() 且 index() 不返回 permissions，
// 故「分配权限」是覆盖式提交，弹窗内已注明。
import { Component, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzModalService } from 'ng-zorro-antd/modal';
import { firstValueFrom } from 'rxjs';

import { API, ApiService } from '../../api/api.service';
import { ENABLE, ENABLE_TAGS, options } from '../../api/dict';
import { Query } from '../../api/types';
import { ConfirmService } from '../../components/confirm.service';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FormField, FormValue, RowAction } from '../../components/types';
import { PermissionModalComponent } from './permission-modal';

interface RoleRow extends Record<string, unknown> {
  id: string;
  name: string;
  slug: string;
  description: string;
  status: number;
  users_count: number;
  created_at: string;
}

@Component({
  selector: 'xz-roles',
  imports: [DataTableComponent, FormModalComponent, NzButtonModule, NzIconModule],
  templateUrl: './roles.html',
})
export class RolesComponent {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);
  private readonly modal = inject(NzModalService);

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<FormValue | null>(null);
  protected readonly refresh = signal(0);

  protected readonly columns: Column[] = [
    { key: 'name', title: '角色名', kind: 'strong', width: '160px' },
    { key: 'slug', title: '标识', width: '180px' },
    { key: 'description', title: '描述', width: '200px' },
    { key: 'users_count', title: '用户数', width: '110px', align: 'right' },
    { key: 'status', title: '状态', width: '100px', kind: 'tag', map: ENABLE_TAGS },
    { key: 'created_at', title: '创建时间', width: '150px', kind: 'datetime' },
  ];

  protected readonly filters = [
    { key: 'keyword', label: '关键词', placeholder: '按角色名称 / 标识筛选' },
  ];

  protected readonly fields: FormField[] = [
    { key: 'name', label: '角色名称', required: true, placeholder: '如：物业管理员' },
    { key: 'slug', label: '角色标识', required: true, placeholder: '如：property_admin', hint: '创建后不可修改（后端 update 不接受 slug）' },
    { key: 'description', label: '描述', kind: 'textarea' },
    { key: 'status', label: '状态', kind: 'select', options: () => options(ENABLE) },
  ];

  protected readonly rowActions: RowAction<RoleRow>[] = [
    { label: '分配权限', run: (row) => this.assign(row) },
    { label: '编辑', run: (row) => this.edit(row) },
    { label: '删除', danger: true, run: (row) => this.remove(row) },
  ];

  /** 角色列表是形状 B（page + limit），走 getManualPage */
  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getManualPage<RoleRow>(API.role, query, page, size);

  protected create(): void {
    this.editing.set(null);
    this.formOpen.set(true);
  }

  private edit(row: RoleRow): void {
    // 后端无 show()，直接用列表行回填（字段足够）
    this.editing.set({
      id: row.id,
      name: row.name,
      slug: row.slug,
      description: row.description,
      status: row.status,
    });
    this.formOpen.set(true);
  }

  private async remove(row: RoleRow): Promise<void> {
    const password = await this.confirm.askPassword(`确认删除角色「${row.name}」？`);
    if (!password) return;
    await firstValueFrom(this.api.delete(`${API.role}/${row.id}`, { password }));
    this.refresh.update((v) => v + 1);
  }

  /** 打开权限树弹窗；返回勾选的 hashid 列表（空数组 = 清空授权），取消返回 null/undefined */
  private pickPermissions(row: RoleRow): Promise<string[] | null | undefined> {
    const ref = this.modal.create<PermissionModalComponent, { roleId: string; roleName: string }, string[] | null>({
      nzTitle: `分配权限 · ${row.name}`,
      nzContent: PermissionModalComponent,
      nzData: { roleId: row.id, roleName: row.name },
      nzWidth: 560,
      nzFooter: null,
    });
    return firstValueFrom(ref.afterClose);
  }

  private async assign(row: RoleRow): Promise<void> {
    const ids = await this.pickPermissions(row);
    // [] 为真值：清空授权是合法操作，只有 null/undefined（取消）才中止
    if (!ids) return;
    await firstValueFrom(this.api.put(`${API.role}/${row.id}`, { permission_ids: ids }));
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> => {
    const editing = this.editing();
    if (editing) {
      // slug 不可改；不带 permission_ids，避免覆盖式清空已有授权
      const { slug: _slug, ...rest } = value;
      return firstValueFrom(this.api.put(`${API.role}/${editing['id']}`, rest));
    }
    return firstValueFrom(this.api.post(API.role, value));
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };
}
