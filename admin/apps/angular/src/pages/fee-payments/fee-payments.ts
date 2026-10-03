// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 缴费记录：只读列表 + 线下缴费登记（POST /admin/fee-payment/offline）。
import { Component, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { firstValueFrom } from 'rxjs';

import { API, ApiService } from '../../api/api.service';
import {
  options,
  PAYMENT_CHANNEL,
  PAYMENT_CHANNEL_TAGS,
  PAYMENT_METHOD,
  PAYMENT_METHOD_TAGS,
} from '../../api/dict';
import { Query } from '../../api/types';
import { DataTableComponent } from '../../components/data-table/data-table';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { Column, FilterField, FormField, FormValue } from '../../components/types';

interface FeePaymentRow extends Record<string, unknown> {
  id: string;
  bill_id: string;
  owner_id: string;
  payment_number: string;
  /** 后端 DECIMAL，序列化为字符串（如 "120.00"） */
  amount: string;
  payment_method: number;
  payment_channel: number;
  paid_at: string;
  /** 操作员为后端数字 ID */
  operator_id: number;
  receipt_url: string;
  remark: string;
  created_at: string;
}

@Component({
  selector: 'xz-fee-payments',
  imports: [DataTableComponent, FormModalComponent, NzButtonModule, NzIconModule],
  templateUrl: './fee-payments.html',
})
export class FeePaymentsComponent {
  private readonly api = inject(ApiService);

  protected readonly refresh = signal(0);
  protected readonly formOpen = signal(false);

  protected readonly columns: Column[] = [
    { key: 'payment_number', title: '支付单号', kind: 'strong', width: '190px' },
    // 「账单」列两端同删（team-lead 2026-10-03）：只显示裸 hashid 等于没有信息，
    // 反查账单编号要额外拉 /admin/fee-bill 且受分页限制（只能覆盖首页），后端 join 又超出本轮范围。
    { key: 'amount', title: '金额', kind: 'money', align: 'right', width: '120px' },
    { key: 'payment_method', title: '支付方式', kind: 'tag', map: PAYMENT_METHOD_TAGS, width: '110px' },
    { key: 'payment_channel', title: '渠道', kind: 'tag', map: PAYMENT_CHANNEL_TAGS, width: '90px' },
    { key: 'paid_at', title: '支付时间', width: '150px' },
    { key: 'operator_id', title: '操作员ID', width: '110px' },
    { key: 'remark', title: '备注', width: '200px' },
    { key: 'created_at', title: '创建时间', width: '150px' },
  ];

  protected readonly filters: FilterField[] = [
    { key: 'keyword', label: '支付单号', placeholder: '输入支付单号搜索' },
    // 原「账单」筛选项同删：输入框里也只能粘贴裸 hashid，与刚删掉的列是同一个理由（React 端同此三项）
    {
      key: 'payment_method',
      label: '支付方式',
      kind: 'select',
      options: () => options(PAYMENT_METHOD),
    },
    {
      key: 'payment_channel',
      label: '渠道',
      kind: 'select',
      options: () => options(PAYMENT_CHANNEL),
    },
  ];

  protected readonly fields: FormField[] = [
    {
      key: 'bill_id',
      label: '账单',
      required: true,
      placeholder: '账单 hashid',
      hint: '填写账单 hashid',
    },
    { key: 'amount', label: '收款金额', kind: 'number', required: true, min: 0.01, step: 0.01 },
    {
      key: 'payment_method',
      label: '支付方式',
      kind: 'select',
      options: () => options(PAYMENT_METHOD),
      hint: '不选默认现金',
    },
    { key: 'paid_at', label: '收款时间', kind: 'date' },
    { key: 'receipt_url', label: '收据URL', wide: true },
    { key: 'remark', label: '备注', kind: 'textarea' },
  ];

  protected readonly loader = (query: Query, page: number, size: number) =>
    this.api.getPage<FeePaymentRow>(API.feePayment, query, page, size);

  protected create(): void {
    this.formOpen.set(true);
  }

  protected readonly submit = async (value: FormValue): Promise<unknown> =>
    firstValueFrom(
      this.api.post(API.feePaymentOffline, {
        bill_id: String(value['bill_id'] ?? ''),
        amount: Number(value['amount']),
        // 省略空值字段，保留后端默认（现金 / 当前时间 / 空备注）
        payment_method: value['payment_method'] ? Number(value['payment_method']) : undefined,
        paid_at: value['paid_at'] || undefined,
        receipt_url: String(value['receipt_url'] ?? '') || undefined,
        remark: String(value['remark'] ?? '') || undefined,
      }),
    );

  protected readonly onSaved = (): void => {
    this.refresh.update((v) => v + 1);
  };
}
