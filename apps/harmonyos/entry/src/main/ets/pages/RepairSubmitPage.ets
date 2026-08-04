/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import router from '@ohos.router';
import { ApiService } from '../services/ApiService';

@Entry
@Component
struct RepairSubmitPage {
  @State category: number = 1;
  @State urgency: number = 0;
  @State description: string = '';
  @State roomId: string = '';
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
  }

  async submit(): Promise<void> {
    if (!this.description) return;
    try {
      const resp = await this.api.post('/service/repair', {
        category: this.category,
        urgency: this.urgency,
        description: this.description,
        room_id: this.roomId || undefined
      }) as Record<string, Object>;
      if (resp['code'] === 0) {
        router.back();
      }
    } catch (e) {
      console.error('Submit failed:', JSON.stringify(e));
    }
  }

  build() {
    Column() {
      Row() {
        Text('提交报修').fontSize(20).fontWeight(FontWeight.Bold)
      }
      .width('100%').padding(16).backgroundColor('#FFF')

      Column() {
        Text('报修类型').fontSize(14).fontColor('#999').margin({ bottom: 8 })
        Row() {
          this.typeChip('水电', 1)
          this.typeChip('门窗', 2)
          this.typeChip('管道', 3)
          this.typeChip('其他', 7)
        }
      }
      .width('100%').padding(16).backgroundColor('#FFF').margin({ top: 8 })

      Column() {
        Text('紧急程度').fontSize(14).fontColor('#999').margin({ bottom: 8 })
        Row() {
          this.urgencyChip('普通', 0)
          this.urgencyChip('紧急', 1)
          this.urgencyChip('非常紧急', 2)
        }
      }
      .width('100%').padding(16).backgroundColor('#FFF').margin({ top: 8 })

      Column() {
        Text('问题描述').fontSize(14).fontColor('#999').margin({ bottom: 8 })
        TextArea({ placeholder: '请描述您遇到的问题...', text: this.description })
          .height(120)
          .onChange((value: string) => { this.description = value; })
      }
      .width('100%').padding(16).backgroundColor('#FFF').margin({ top: 8 })

      Button('提交报修')
        .width('90%').margin({ top: 24 })
        .backgroundColor('#007AFF')
        .borderRadius(8)
        .onClick(() => { this.submit(); })
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder typeChip(label: string, value: number) {
    Text(label)
      .fontSize(14)
      .fontColor(this.category === value ? '#FFF' : '#333')
      .backgroundColor(this.category === value ? '#007AFF' : '#E8E8E8')
      .borderRadius(8)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .margin({ right: 8 })
      .onClick(() => { this.category = value; })
  }

  @Builder urgencyChip(label: string, value: number) {
    Text(label)
      .fontSize(14)
      .fontColor(this.urgency === value ? '#FFF' : '#333')
      .backgroundColor(this.urgency === value ? '#007AFF' : '#E8E8E8')
      .borderRadius(8)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .margin({ right: 8 })
      .onClick(() => { this.urgency = value; })
  }
}
