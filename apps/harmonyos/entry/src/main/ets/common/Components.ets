/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * 空状态组件（对齐管理端 common/Components.ets 的 EmptyView；
 * 业主端 rawfile 无 empty.png，按小筑品牌复用 logo.png，不新增资产）
 */
@Component
export struct EmptyView {
  @Prop message: string = '暂无数据';

  build() {
    Column() {
      Image($rawfile('logo.png'))
        .width(120)
        .height(120)
        .objectFit(ImageFit.Contain)

      Text(this.message)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }
}
