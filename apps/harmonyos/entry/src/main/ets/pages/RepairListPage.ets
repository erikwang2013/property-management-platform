/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import router from '@ohos.router';
import { ApiService } from '../services/ApiService';
import { RepairOrder } from '../model/Models';

@Entry
@Component
struct RepairListPage {
  @State repairs: RepairOrder[] = [];
  @State loading: boolean = true;
  @State statusFilter: string = '';
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
    this.loadRepairs();
  }

  async loadRepairs(): Promise<void> {
    this.loading = true;
    try {
      let path = '/service/repairs?page=1&per_page=50';
      if (this.statusFilter) path += `&status=${this.statusFilter}`;
      const resp = await this.api.get(path) as Record<string, Object>;
      if (resp['code'] === 0) {
        this.repairs = (resp['data'] as RepairOrder[]) || [];
      }
    } catch (e) {}
    this.loading = false;
  }

  statusLabel(status: number): string {
    const labels: Record<number, string> = { 0: '待处理', 1: '已分配', 2: '维修中', 3: '已完成', 4: '已评价', 5: '已取消' };
    return labels[status] || '未知';
  }

  categoryLabel(cat: number): string {
    const labels: Record<number, string> = { 1: '水电', 2: '门窗', 3: '管道', 4: '墙面', 5: '家电', 6: '电梯', 7: '其他' };
    return labels[cat] || '其他';
  }

  urgencyLabel(u: number): string {
    const labels: Record<number, string> = { 0: '普通', 1: '紧急', 2: '非常紧急' };
    return labels[u] || '普通';
  }

  build() {
    Column() {
      Row() {
        Text('报修记录')
          .fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Text('提交报修')
          .fontSize(14).fontColor('#007AFF')
          .onClick(() => { router.pushUrl({ url: 'pages/RepairSubmitPage' }); })
      }
      .width('100%').padding(16).backgroundColor('#FFF')

      // Filter row
      Row() {
        this.filterChip('全部', '')
        this.filterChip('待处理', '0')
        this.filterChip('处理中', '1')
        this.filterChip('已完成', '3')
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

      if (this.loading) {
        Column() { LoadingProgress().width(40).height(40) }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.repairs, (r: RepairOrder) => {
            ListItem() {
              Column() {
                Row() {
                  Text(this.categoryLabel(r.category))
                    .fontSize(14).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.statusLabel(r.status))
                    .fontSize(11).fontColor('#FFF')
                    .backgroundColor('#007AFF').borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                .width('100%')
                Row() {
                  Text(`${r.room_number} | ${this.urgencyLabel(r.urgency)}`)
                    .fontSize(12).fontColor('#999')
                }
                .width('100%').margin({ top: 4 })
                Text(r.description || '')
                  .fontSize(13).fontColor('#333').margin({ top: 4 }).maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
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

  @Builder filterChip(label: string, status: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.statusFilter === status ? '#FFF' : '#333')
      .backgroundColor(this.statusFilter === status ? '#007AFF' : '#E8E8E8')
      .borderRadius(16)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .margin({ right: 8 })
      .onClick(() => { this.statusFilter = status; this.loadRepairs(); })
  }
}
