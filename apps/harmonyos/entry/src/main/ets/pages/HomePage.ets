/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import router from '@ohos.router';
import { ApiService } from '../services/ApiService';
import { Announcement } from '../model/Models';

@Entry
@Component
struct HomePage {
  @State announcements: Announcement[] = [];
  @State balance: number = 0;
  @State pendingRepairs: number = 0;
  @State rooms: number = 0;
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
    this.loadDashboard();
  }

  async loadDashboard(): Promise<void> {
    try {
      const resp = await this.api.get('/service/home') as Record<string, Object>;
      if (resp['code'] === 0) {
        const data = resp['data'] as Record<string, Object>;
        this.balance = parseFloat(data['pending_amount'] as string) || 0;
        this.pendingRepairs = (data['repairing_count'] as number) || 0;
        this.rooms = (data['room_count'] as number) || 0;
        this.announcements = (data['announcements'] as Announcement[]) || [];
      }
    } catch (e) {
      console.error('Failed to load dashboard:', JSON.stringify(e));
    }
  }

  build() {
    Column() {
      // Title bar
      Row() {
        Text('物业管理平台')
          .fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Text('退出')
          .fontSize(14).fontColor('#007AFF')
          .onClick(() => {
            router.replaceUrl({ url: 'pages/LoginPage' });
          })
      }
      .width('100%').padding(16)

      // Stat cards
      Row() {
        this.statCard('待缴费用', `¥${this.balance.toFixed(2)}`, '#FF6B6B')
        this.statCard('维修工单', `${this.pendingRepairs}个`, '#4ECDC4')
        this.statCard('我的房产', `${this.rooms}套`, '#45B7D1')
      }
      .width('100%').padding({ left: 16, right: 16 }).justifyContent(FlexAlign.SpaceBetween)

      // Announcements
      List() {
        ForEach(this.announcements, (item: Announcement) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.title)
                  .fontSize(16).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.published_at)
                  .fontSize(12).fontColor('#999').margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start).layoutWeight(1)

              Text(this.categoryLabel(item.category))
                .fontSize(11).fontColor('#FFF')
                .backgroundColor('#007AFF').borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 })
            }
            .width('100%').padding(12)
          }
        })
      }
      .layoutWeight(1).margin({ top: 16 }).padding({ left: 16, right: 16 })
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder statCard(label: string, value: string, color: string) {
    Column() {
      Text(value).fontSize(22).fontWeight(FontWeight.Bold).fontColor(color)
      Text(label).fontSize(12).fontColor('#999').margin({ top: 4 })
    }
    .width('30%').height(80)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFF')
    .borderRadius(8)
    .shadow({ radius: 4, color: '#00000010', offsetX: 0, offsetY: 2 })
  }

  categoryLabel(category: number): string {
    const labels: Record<number, string> = { 1: '通知', 2: '活动', 3: '公告' };
    return labels[category] || '通知';
  }
}
