// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 系统配置：手工分页形状（getManualPage）+ 弹窗表单；无详情接口，编辑直接用列表行。
import { Component, computed, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { firstValueFrom } from 'rxjs';

import { API, ApiService } from '../../api/api.service';
import { Option, Query } from '../../api/types';
import { ConfirmService } from '../../components/confirm.service';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FormField, FormValue, RowAction } from '../../components/types';

/** 值类型是字符串枚举（dict.ts 的 Dict 是数字键，用不了 options()，直接给 Option[]） */
const CONFIG_TYPES: Option[] = ['string', 'int', 'bool', 'json', 'array'].map((value) => ({
  label: value,
  value,
}));

interface ConfigRow extends Record<string, unknown> {
  id: string;
  group: string;
  key: string;
  value: string | null;
  type: string;
  description: string;
  created_at: string;
  updated_at: string;
}

@Component({
  selector: 'xz-system',
  imports: [DataTableComponent, FormModalComponent, NzButtonModule, NzIconModule],
  templateUrl: './system.html',
})
export class SystemComponent {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<FormValue | null>(null);
  protected readonly refresh = signal(0);

  protected readonly columns: Column[] = [
    { key: 'group', title: '分组', width: '140px' },
    { key: 'key', title: '配置键', width: '180px', kind: 'strong' },
    // 配置值/说明两列内容是长文本，声明 240 是算出来的：声明和 1050，1440 视口下容器 1068，
    // 取 260 会恒定出 22px 横向滚动条。加 ellipsis 让声明宽成为硬约束（§1.3 第 51 行）。
    { key: 'value', title: '配置值', width: '240px', ellipsis: true },
    { key: 'type', title: '类型', width: '100px' },
    { key: 'description', title: '说明', width: '240px', ellipsis: true },
    { key: 'updated_at', title: '更新时间', width: '150px', kind: 'datetime' },
  ];

  // 后端只按 group 过滤，key 不作为筛选项（发了也不生效）
  protected readonly filters = [
    { key: 'group', label: '分组', placeholder: '按分组精确筛选' },
  ];

  protected readonly rowActions: RowAction<ConfigRow>[] = [
    { label: '编辑', run: (row) => this.edit(row) },
    { label: '删除', danger: true, run: (row) => this.remove(row) },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getManualPage<ConfigRow>(API.config, query, page, size);

  private readonly tailFields: FormField[] = [
    { key: 'value', label: '配置值', required: true, kind: 'textarea' },
    {
      key: 'type',
      label: '值类型',
      kind: 'select',
      options: () => CONFIG_TYPES,
      hint: '留空按 string 处理',
    },
    { key: 'description', label: '说明' },
  ];

  private readonly createFields: FormField[] = [
    { key: 'group', label: '分组', required: true, placeholder: '如：site' },
    { key: 'key', label: '配置键', required: true, placeholder: '如：site_name' },
    ...this.tailFields,
  ];

  private readonly editFields: FormField[] = [
    { key: 'group', label: '分组', immutable: true },
    { key: 'key', label: '配置键', immutable: true, hint: '分组与配置键不可修改' },
    ...this.tailFields,
  ];

  protected readonly fields = computed<FormField[]>(() =>
    this.editing() ? this.editFields : this.createFields,
  );

  private edit(row: ConfigRow): void {
    // ConfigController 没有详情接口，列表返回的就是全字段明文
    this.editing.set({
      id: row.id,
      group: row.group,
      key: row.key,
      value: row.value,
      type: row.type,
      description: row.description,
    });
    this.formOpen.set(true);
  }

  private async remove(row: ConfigRow): Promise<void> {
    const password = await this.confirm.askPassword(`确认删除配置「${row.group}.${row.key}」？`);
    if (!password) return;
    await firstValueFrom(this.api.delete(`${API.config}/${row.id}`, { password }));
    this.refresh.update((v) => v + 1);
  }

  protected create(): void {
    this.editing.set(null);
    this.formOpen.set(true);
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> => {
    const editing = this.editing();
    const payload: FormValue = { ...value };
    // 类型留空交给后端默认 string（store 的 input('type','string') 遇空串会存成空串）
    if (payload['type'] === '') delete payload['type'];
    if (editing) {
      return firstValueFrom(this.api.put(`${API.config}/${editing['id']}`, payload));
    }
    return firstValueFrom(this.api.post(API.config, payload));
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };
}
