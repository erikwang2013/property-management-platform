/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import { ApiService } from '../services/ApiService';
import { ParkingVehicle, ParkingSpace, ParkingRecord } from '../model/Models';

@Entry
@Component
struct ParkingPage {
  @State tab: string = 'vehicles';
  @State loading: boolean = true;
  @State vehicles: ParkingVehicle[] = [];
  @State spaces: ParkingSpace[] = [];
  @State records: ParkingRecord[] = [];
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
    this.loadAll();
  }

  async loadAll(): Promise<void> {
    this.loading = true;
    try {
      const [v, s, r] = await Promise.all([
        this.api.get('/service/parking/vehicles?page=1&per_page=50'),
        this.api.get('/service/parking/spaces?page=1&per_page=50'),
        this.api.get('/service/parking/records?page=1&per_page=50')
      ]);
      if ((v as Record<string, Object>)['code'] === 0) {
        this.vehicles = ((v as Record<string, Object>)['data'] as ParkingVehicle[]) || [];
      }
      if ((s as Record<string, Object>)['code'] === 0) {
        this.spaces = ((s as Record<string, Object>)['data'] as ParkingSpace[]) || [];
      }
      if ((r as Record<string, Object>)['code'] === 0) {
        this.records = ((r as Record<string, Object>)['data'] as ParkingRecord[]) || [];
      }
    } catch (e) {}
    this.loading = false;
  }

  vehicleTypeLabel(t: number): string {
    const labels: Record<number, string> = { 1: '小汽车', 2: 'SUV', 3: 'MPV', 4: '货车', 5: '新能源' };
    return labels[t] || '其他';
  }

  spaceTypeLabel(t: number): string {
    return t === 2 ? '地下' : '地上';
  }

  spaceStatusLabel(s: number): string {
    const labels: Record<number, string> = { 0: '空闲', 1: '已售', 2: '已租', 3: '维修' };
    return labels[s] || '未知';
  }

  vehicleStatusLabel(s: number): string {
    return s === 1 ? '正常' : '过期';
  }

  build() {
    Column() {
      Row() {
        Text('停车管理').fontSize(20).fontWeight(FontWeight.Bold)
      }
      .width('100%').padding(16).backgroundColor('#FFF')

      Row() {
        this.tabChip('我的车辆', 'vehicles')
        this.tabChip('我的车位', 'spaces')
        this.tabChip('停车记录', 'records')
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

      if (this.loading) {
        Column() { LoadingProgress().width(40).height(40) }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.tab === 'vehicles') {
        List() {
          ForEach(this.vehicles, (v: ParkingVehicle) => {
            ListItem() {
              Column() {
                Row() {
                  Text(v.plate_number).fontSize(15).fontWeight(FontWeight.Bold)
                  Blank()
                  Text(this.vehicleStatusLabel(v.status))
                    .fontSize(11).fontColor('#FFF')
                    .backgroundColor(v.status === 1 ? '#4CAF50' : '#FF6B6B').borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                .width('100%')
                Text(`${this.vehicleTypeLabel(v.vehicle_type)} | ${v.vehicle_brand || '未填品牌'} ${v.vehicle_color || ''}`)
                  .fontSize(12).fontColor('#999').margin({ top: 4 })
                Row() {
                  Text(v.space ? `绑定车位 ${v.space.space_number}（${v.space.space_type === 2 ? '地下' : '地上'}）` : '未绑定车位')
                    .fontSize(12).fontColor('#007AFF')
                  Blank()
                  Text(v.end_date ? `有效期至 ${v.end_date}` : '').fontSize(11).fontColor('#BBB')
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
      } else if (this.tab === 'spaces') {
        List() {
          ForEach(this.spaces, (s: ParkingSpace) => {
            ListItem() {
              Column() {
                Row() {
                  Text(s.space_number).fontSize(15).fontWeight(FontWeight.Bold)
                  Blank()
                  Text(this.spaceStatusLabel(s.status))
                    .fontSize(11).fontColor('#FFF')
                    .backgroundColor(s.status === 0 ? '#4CAF50' : '#FF9F43').borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                .width('100%')
                Text(`${this.spaceTypeLabel(s.space_type)} | ${s.area}m² | 月费 ¥${s.fee_monthly}`)
                  .fontSize(12).fontColor('#999').margin({ top: 4 })
              }
              .width('100%').padding(12)
              .backgroundColor('#FFF').borderRadius(8)
              .margin({ left: 16, right: 16, bottom: 8 })
            }
          })
        }
        .layoutWeight(1).margin({ top: 8 })
      } else {
        List() {
          ForEach(this.records, (r: ParkingRecord) => {
            ListItem() {
              Column() {
                Row() {
                  Text(r.plate_number).fontSize(15).fontWeight(FontWeight.Bold)
                  Blank()
                  Text(`¥${r.fee}`).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FF6B6B')
                }
                .width('100%')
                Text(`${r.entry_time} → ${r.exit_time || '在场'}`)
                  .fontSize(12).fontColor('#999').margin({ top: 4 })
                Text(`${Math.floor(r.duration / 60)}小时${r.duration % 60}分`)
                  .fontSize(11).fontColor('#BBB').margin({ top: 4 })
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

  @Builder tabChip(label: string, value: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.tab === value ? '#FFF' : '#333')
      .backgroundColor(this.tab === value ? '#007AFF' : '#E8E8E8')
      .borderRadius(16)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .margin({ right: 8 })
      .onClick(() => { this.tab = value; })
  }
}
