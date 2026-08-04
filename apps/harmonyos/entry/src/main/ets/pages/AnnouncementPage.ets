/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import { ApiService } from '../services/ApiService';
import { Announcement } from '../model/Models';

@Entry
@Component
struct AnnouncementPage {
  @State announcements: Announcement[] = [];
  @State loading: boolean = true;
  @State selectedItem: Announcement | null = null;
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
    this.loadList();
  }

  async loadList(): Promise<void> {
    this.loading = true;
    try {
      const resp = await this.api.get('/service/announcements?page=1&per_page=50') as Record<string, Object>;
      if (resp['code'] === 0) {
        this.announcements = (resp['data'] as Announcement[]) || [];
      }
    } catch (e) {}
    this.loading = false;
  }

  build() {
    if (this.selectedItem) {
      // Detail view
      Column() {
        Row() {
          Text('← 返回')
            .fontSize(14).fontColor('#007AFF')
            .onClick(() => { this.selectedItem = null; })
          Blank()
        }
        .width('100%').padding(16).backgroundColor('#FFF')

        Column() {
          Text(this.selectedItem.title)
            .fontSize(20).fontWeight(FontWeight.Bold)
          Text(this.selectedItem.published_at)
            .fontSize(12).fontColor('#999').margin({ top: 8 })
        }
        .width('100%').padding(16).backgroundColor('#FFF').margin({ top: 8 })
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5')
    } else {
      // List view
      Column() {
        Row() {
          Text('社区公告').fontSize(20).fontWeight(FontWeight.Bold)
        }
        .width('100%').padding(16).backgroundColor('#FFF')

        if (this.loading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.announcements, (item: Announcement) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(item.title)
                      .fontSize(16).fontWeight(FontWeight.Medium).maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.published_at)
                      .fontSize(12).fontColor('#999').margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Image($r('app.media.icon'))
                    .width(16).height(16).fillColor('#CCC')
                }
                .width('100%').padding(16)
                .backgroundColor('#FFF').borderRadius(8)
                .margin({ left: 16, right: 16, bottom: 8 })
                .onClick(() => { this.selectedItem = item; })
              }
            })
          }
          .layoutWeight(1)
        }
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5')
    }
  }
}
