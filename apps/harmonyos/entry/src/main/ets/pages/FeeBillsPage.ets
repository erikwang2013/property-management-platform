/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import router from '@ohos.router';
import { ApiService } from '../services/ApiService';
import { FeeBill } from '../model/Models';

@Entry
@Component
struct FeeBillsPage {
  @State bills: FeeBill[] = [];
  @State loading: boolean = true;
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
    this.loadBills();
  }

  async loadBills(): Promise<void> {
    this.loading = true;
    try {
      const resp = await this.api.get('/service/fees/bills?page=1&per_page=50') as Record<string, Object>;
      if (resp['code'] === 0) {
        this.bills = (resp['data'] as FeeBill[]) || [];
      }
    } catch (e) {
      console.error('Failed to load bills:', JSON.stringify(e));
    }
    this.loading = false;
  }

  statusLabel(status: number): string {
    const labels: Record<number, string> = { 0: '待缴', 1: '已缴', 2: '逾期', 3: '部分缴纳' };
    return labels[status] || '未知';
  }

  statusColor(status: number): string {
    const colors: Record<number, string> = { 0: '#FF6B6B', 1: '#4ECDC4', 2: '#FF4444', 3: '#FFA500' };
    return colors[status] || '#999';
  }

  build() {
    Column() {
      Row() {
        Text('我的账单')
          .fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%').padding(16).backgroundColor('#FFF')

      if (this.loading) {
        Column() {
          LoadingProgress().width(40).height(40)
          Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 8 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.bills.length === 0) {
        Column() {
          Text('暂无账单').fontSize(16).fontColor('#999')
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.bills, (bill: FeeBill) => {
            ListItem() {
              Column() {
                Row() {
                  Text(bill.fee_type_name)
                    .fontSize(16).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(`¥${bill.amount.toFixed(2)}`)
                    .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FF6B6B')
                }
                .width('100%')
                Row() {
                  Text(`${bill.room_number} | 截止: ${bill.due_date}`)
                    .fontSize(12).fontColor('#999')
                  Blank()
                  Text(this.statusLabel(bill.status))
                    .fontSize(11).fontColor('#FFF')
                    .backgroundColor(this.statusColor(bill.status))
                    .borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                .width('100%').margin({ top: 4 })
              }
              .width('100%').padding(12)
              .backgroundColor('#FFF').borderRadius(8)
              .margin({ left: 16, right: 16, bottom: 8 })
            }
          })
        }
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
