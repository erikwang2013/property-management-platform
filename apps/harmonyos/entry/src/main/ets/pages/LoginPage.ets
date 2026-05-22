/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import router from '@ohos.router';
import { AuthService } from '../services/AuthService';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State password: string = '';
  @State loading: boolean = false;
  private auth: AuthService = new AuthService();

  build() {
    Column() {
      Text('物业管理平台')
        .fontSize(24).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
      Text('业主登录')
        .fontSize(14).fontColor('#999').margin({ bottom: 32 })

      TextInput({ placeholder: '请输入手机号', text: this.phone })
        .type(InputType.PhoneNumber).maxLength(11)
        .onChange((value: string) => { this.phone = value; })
        .margin({ bottom: 16 })

      TextInput({ placeholder: '请输入密码', text: this.password })
        .type(InputType.Password)
        .onChange((value: string) => { this.password = value; })
        .margin({ bottom: 24 })

      Button('登 录')
        .width('100%').height(44)
        .enabled(!this.loading)
        .onClick(async () => {
          this.loading = true;
          try {
            await this.auth.login(this.phone, this.password, '', []);
            router.replaceUrl({ url: 'pages/HomePage' });
          } catch (e) {
            AlertDialog.show({ message: '登录失败: ' + JSON.stringify(e) });
          }
          this.loading = false;
        })

      Button('还没有账号？立即注册')
        .type(ButtonType.Normal).backgroundColor(Color.Transparent)
        .margin({ top: 12 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(32)
  }
}
