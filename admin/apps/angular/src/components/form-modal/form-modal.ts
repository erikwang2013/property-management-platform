// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 通用表单弹窗：按字段描述符生成响应式表单，13 个模块复用一个弹窗。
import { Component, computed, effect, inject, input, model, signal } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzDatePickerModule } from 'ng-zorro-antd/date-picker';
import { NzFormModule } from 'ng-zorro-antd/form';
import { NzGridModule } from 'ng-zorro-antd/grid';
import { NzInputModule } from 'ng-zorro-antd/input';
import { NzInputNumberModule } from 'ng-zorro-antd/input-number';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzModalModule } from 'ng-zorro-antd/modal';
import { NzSelectModule } from 'ng-zorro-antd/select';
import { NzSwitchModule } from 'ng-zorro-antd/switch';

import { errorText } from '../../api/api.service';
import { DateValueCache } from '../date-value';
import { FormField, FormValue } from '../types';

@Component({
  selector: 'xz-form-modal',
  imports: [
    FormsModule,
    ReactiveFormsModule,
    NzButtonModule,
    NzDatePickerModule,
    NzFormModule,
    NzGridModule,
    NzInputModule,
    NzInputNumberModule,
    NzModalModule,
    NzSelectModule,
    NzSwitchModule,
  ],
  templateUrl: './form-modal.html',
  styleUrl: './form-modal.scss',
})
export class FormModalComponent {
  private readonly fb = inject(FormBuilder);
  private readonly message = inject(NzMessageService);

  readonly open = model(false);
  readonly title = input('编辑');
  readonly fields = input.required<FormField[]>();
  /** 初始值；null 表示新增 */
  readonly values = input<FormValue | null>(null);
  /** 提交回调；返回值透传给 onSaved */
  readonly submit = input.required<(value: FormValue) => Promise<unknown>>();
  readonly onSaved = input<(result: unknown) => void>();

  protected readonly saving = signal(false);
  protected readonly form = this.fb.group({});
  protected readonly isEdit = computed(() => this.values() !== null);
  /** 模板里取不到全局 Number，数字上限在这里给 */
  protected readonly maxNumber = Number.MAX_SAFE_INTEGER;

  /** immutable 字段仅在编辑态锁定（新增时仍需选择，如房产所属小区） */
  protected locked(f: FormField): boolean {
    return !!f.immutable && this.isEdit();
  }

  constructor() {
    // 打开时按 fields + values 重建表单；fields/values 非 signal 读写，不会成环
    effect(() => {
      if (!this.open()) return;
      this.build(this.fields(), this.values());
    });
  }

  private build(fields: FormField[], values: FormValue | null): void {
    for (const key of Object.keys(this.form.controls)) this.form.removeControl(key);
    const edit = values !== null;
    for (const f of fields) {
      this.form.addControl(
        f.key,
        this.fb.control(
          {
            value: values?.[f.key] ?? this.emptyValue(f),
            disabled: edit && !!f.immutable,
          },
          f.required ? [Validators.required] : [],
        ),
      );
    }
  }

  private emptyValue(f: FormField): string | number | boolean | null {
    switch (f.kind) {
      case 'switch':
        return true;
      case 'number':
        return null;
      default:
        return '';
    }
  }

  protected async ok(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.message.warning('请填写必填项');
      return;
    }
    this.saving.set(true);
    try {
      const result = await this.submit()(this.form.getRawValue() as FormValue);
      this.message.success(this.isEdit() ? '更新成功' : '创建成功');
      this.open.set(false);
      this.onSaved()?.(result);
    } catch (err) {
      this.message.error(errorText(err));
    } finally {
      this.saving.set(false);
    }
  }

  protected cancel(): void {
    this.open.set(false);
  }

  /** 必须走缓存：模板每次 CD 都调它，返回新 Date 身份会引发无限重渲染（见 date-value.ts 的注释） */
  private readonly dateCache = new DateValueCache();

  protected dateValue(key: string): Date | null {
    return this.dateCache.get(key, this.form.get(key)?.value);
  }

  protected setDate(key: string, date: Date | null): void {
    this.form.get(key)?.setValue(date ? formatDate(date) : '');
  }

  protected invalid(key: string): boolean {
    const c = this.form.get(key);
    return !!c && c.invalid && c.touched;
  }
}

export function formatDate(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
