// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 标准 CRUD 样板：搜索 + 分页 + 弹窗表单 + 行操作（其余模块按此模式扩展）
import { Component, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { firstValueFrom } from 'rxjs';

import { API, ApiService } from '../../api/api.service';
import { NORMAL, NORMAL_TAGS, options } from '../../api/dict';
import { Option, Query } from '../../api/types';
import { ConfirmService } from '../../components/confirm.service';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FormField, FormValue, RowAction } from '../../components/types';

interface CommunityRow extends Record<string, unknown> {
  id: string;
  name: string;
  address: string;
  city: string;
  building_count: number;
  room_count: number;
  property_company: string;
  status: number;
  created_at: string;
}

@Component({
  selector: 'xz-communities',
  imports: [DataTableComponent, FormModalComponent, NzButtonModule, NzIconModule],
  templateUrl: './communities.html',
})
export class CommunitiesComponent {
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmService);

  protected readonly formOpen = signal(false);
  protected readonly editing = signal<FormValue | null>(null);
  protected readonly refresh = signal(0);

  protected readonly columns: Column[] = [
    { key: 'name', title: '小区名称', kind: 'strong', width: '180px' },
    { key: 'city', title: '城市', width: '120px' },
    { key: 'address', title: '地址', width: '220px' },
    { key: 'building_count', title: '楼栋数', width: '90px', align: 'right' },
    { key: 'room_count', title: '房屋套数', width: '90px', align: 'right' },
    { key: 'property_company', title: '物业公司', width: '160px' },
    { key: 'status', title: '状态', width: '100px', kind: 'tag', map: NORMAL_TAGS },
    { key: 'created_at', title: '创建时间', width: '150px' },
  ];

  protected readonly filters = [
    { key: 'keyword', label: '小区名称', placeholder: '输入小区名称搜索' },
    { key: 'status', label: '状态', kind: 'select' as const, options: () => options(NORMAL) },
  ];

  protected readonly fields: FormField[] = [
    { key: 'name', label: '小区名称', required: true, placeholder: '如：阳光花园' },
    { key: 'city', label: '城市' },
    { key: 'province', label: '省份' },
    { key: 'district', label: '区/县' },
    { key: 'address', label: '详细地址', wide: true },
    { key: 'property_company', label: '物业公司' },
    { key: 'developer', label: '开发商' },
    { key: 'contact_phone', label: '联系电话' },
    { key: 'area_total', label: '总建筑面积(m²)', kind: 'number', min: 0 },
    { key: 'description', label: '简介', kind: 'textarea' },
  ];

  protected readonly rowActions: RowAction<CommunityRow>[] = [
    { label: '编辑', run: (row) => this.edit(row) },
    { label: '删除', danger: true, run: (row) => this.remove(row) },
  ];

  protected readonly loader = (_query: Query, page: number, size: number) =>
    this.api.getPage<CommunityRow>(API.community, _query, page, size);

  private async edit(row: CommunityRow): Promise<void> {
    // 列表只有部分字段，编辑前取详情补全
    const detail = await firstValueFrom(this.api.get<FormValue>(`${API.community}/${row.id}`));
    this.editing.set(detail);
    this.formOpen.set(true);
  }

  private async remove(row: CommunityRow): Promise<void> {
    const password = await this.confirm.askPassword(`确认删除小区「${row.name}」？`);
    if (!password) return;
    await firstValueFrom(this.api.delete(`${API.community}/${row.id}`, { password }));
    this.refresh.update((v) => v + 1);
  }

  protected create(): void {
    this.editing.set(null);
    this.formOpen.set(true);
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> => {
    const editing = this.editing();
    if (editing) {
      return firstValueFrom(this.api.put(`${API.community}/${editing['id']}`, value));
    }
    return firstValueFrom(this.api.post(API.community, value));
  };

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };

  protected readonly statusOptions = (): Option[] => options(NORMAL);
}
