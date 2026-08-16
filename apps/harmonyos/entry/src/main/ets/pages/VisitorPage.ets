/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import { ApiService } from '../services/ApiService';
import { Visitor } from '../model/Models';

@Entry
@Component
struct VisitorPage {
  @State visitors: Visitor[] = [];
  @State loading: boolean = true;
  @State showForm: boolean = false;
  @State newPassCode: string = '';
  @State visitorName: string = '';
  @State visitorPhone: string = '';
  @State plateNumber: string = '';
  @State purpose: string = '';
  @State visitorCount: number = 1;
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
    this.loadVisitors();
  }

  async loadVisitors(): Promise<void> {
    this.loading = true;
    try {
      const resp = await this.api.get('/service/visitors?page=1&per_page=50') as Record<string, Object>;
      if (resp['code'] === 0) {
        this.visitors = (resp['data'] as Visitor[]) || [];
      }
    } catch (e) {}
    this.loading = false;
  }

  async submit(): Promise<void> {
    if (!this.visitorName || !this.visitorPhone) return;
    try {
      const payload: Record<string, Object> = {
        visitor_name: this.visitorName,
        visitor_phone: this.visitorPhone,
        visitor_count: this.visitorCount,
        purpose: this.purpose
      };
      if (this.plateNumber) payload['plate_number'] = this.plateNumber;
      const resp = await this.api.post('/service/visitor', payload) as Record<string, Object>;
      if (resp['code'] === 0) {
        const data = resp['data'] as Record<string, Object>;
        this.newPassCode = (data['pass_code'] as string) || '';
        this.showForm = false;
        this.visitorName = '';
        this.visitorPhone = '';
        this.plateNumber = '';
        this.purpose = '';
        this.visitorCount = 1;
        this.loadVisitors();
      }
    } catch (e) {}
  }

  statusLabel(status: number): string {
    const labels: Record<number, string> = { 0: '已预约', 1: '已到访', 2: '已离开', 3: '已取消' };
    return labels[status] || '未知';
  }

  build() {
    Column() {
      Row() {
        Text('访客预约').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Text(this.showForm ? '收起' : '新增预约')
          .fontSize(14).fontColor('#007AFF')
          .onClick(() => { this.showForm = !this.showForm; })
      }
      .width('100%').padding(16).backgroundColor('#FFF')

      if (this.newPassCode) {
        Row() {
          Text(`通行码: ${this.newPassCode}`)
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#007AFF')
          Blank()
          Text('复制')
            .fontSize(13).fontColor('#FFF').backgroundColor('#007AFF')
            .borderRadius(4).padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .onClick(() => { this.newPassCode = ''; })
        }
        .width('100%').padding(16).backgroundColor('#E8F3FF').margin({ top: 8 })
      }

      if (this.showForm) {
        Column() {
          TextInput({ placeholder: '访客姓名', text: this.visitorName })
            .onChange((v: string) => { this.visitorName = v; })
          TextInput({ placeholder: '访客电话', text: this.visitorPhone })
            .margin({ top: 8 }).onChange((v: string) => { this.visitorPhone = v; })
          TextInput({ placeholder: '车牌号（可选）', text: this.plateNumber })
            .margin({ top: 8 }).onChange((v: string) => { this.plateNumber = v; })
          TextInput({ placeholder: '到访事由', text: this.purpose })
            .margin({ top: 8 }).onChange((v: string) => { this.purpose = v; })
          Row() {
            ForEach([1, 2, 3, 4, 5], (n: number) => {
              Text(`${n}人`)
                .fontSize(13)
                .fontColor(this.visitorCount === n ? '#FFF' : '#333')
                .backgroundColor(this.visitorCount === n ? '#007AFF' : '#E8E8E8')
                .borderRadius(16).padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .margin({ right: 8, top: 8 })
                .onClick(() => { this.visitorCount = n; })
            })
          }
          Button('提交预约').width('100%').margin({ top: 16 })
            .backgroundColor('#007AFF').borderRadius(8)
            .onClick(() => { this.submit(); })
        }
        .width('100%').padding(16).backgroundColor('#FFF').margin({ top: 8 })
      }

      if (this.loading) {
        Column() { LoadingProgress().width(40).height(40) }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.visitors, (v: Visitor) => {
            ListItem() {
              Column() {
                Row() {
                  Text(v.visitor_name).fontSize(15).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.statusLabel(v.status))
                    .fontSize(11).fontColor('#FFF')
                    .backgroundColor('#007AFF').borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                .width('100%')
                Text(`${v.visitor_phone} | ${v.visitor_count}人 | ${v.purpose || '来访'}`)
                  .fontSize(12).fontColor('#999').margin({ top: 4 })
                Row() {
                  Text(`通行码 ${v.pass_code}`).fontSize(13).fontColor('#007AFF')
                  Blank()
                  Text(v.created_at).fontSize(11).fontColor('#BBB')
                }
                .width('100%').margin({ top: 4 })
              }
              .width('100%').padding(12)
              .backgroundColor('#FFF').borderRadius(8)
              .margin({ left: 16, right: 16, bottom: 8 })
            }
          })
        }
        .layoutWeight(1).margin({ top: 8 })
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
