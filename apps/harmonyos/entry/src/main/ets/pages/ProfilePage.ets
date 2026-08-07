/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ApiService } from '../services/ApiService';
import { PasswordRequest } from '../model/Models';

@Entry
@Component
struct ProfilePage {
  @State username: string = '';
  @State phone: string = '';
  @State oldPassword: string = '';
  @State newPassword: string = '';
  private api: ApiService = ApiService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.api.init();
    this.loadProfile();
  }

  async loadProfile(): Promise<void> {
    try {
      const resp = await this.api.get('/service/profile') as Record<string, Object>;
      if (resp['code'] === 0) {
        const data = resp['data'] as Record<string, string>;
        this.username = data['username'] || data['name'] || '';
        this.phone = data['phone'] || '';
      }
    } catch (e) {}
  }

  async changePassword(): Promise<void> {
    if (!this.oldPassword || !this.newPassword) {
      promptAction.showToast({ message: '请输入旧密码和新密码' });
      return;
    }
    try {
      const params: PasswordRequest = { old_password: this.oldPassword, new_password: this.newPassword };
      const resp = await this.api.put('/service/profile/password', params) as Record<string, Object>;
      if (resp['code'] === 0) {
        promptAction.showToast({ message: '密码修改成功' });
        this.oldPassword = '';
        this.newPassword = '';
      } else {
        promptAction.showToast({ message: resp['message'] as string || '修改失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '修改失败，请重试' });
    }
  }

  async logout(): Promise<void> {
    try {
      await this.api.post('/service/profile/logout');
    } catch (e) {}
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Column() {
      Row() {
        Text('个人中心').fontSize(20).fontWeight(FontWeight.Bold)
      }
      .width('100%').padding(16).backgroundColor('#FFF')

      Column() {
        Text(this.username || '用户')
          .fontSize(20).fontWeight(FontWeight.Bold)
        Text(this.phone || '')
          .fontSize(14).fontColor('#999').margin({ top: 4 })
      }
      .width('100%').padding(20).backgroundColor('#FFF').margin({ top: 8 })
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('修改密码').fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 12 })
        TextInput({ placeholder: '旧密码', text: this.oldPassword })
          .type(InputType.Password).width('100%').margin({ bottom: 8 })
          .onChange((v: string) => { this.oldPassword = v; })
        TextInput({ placeholder: '新密码', text: this.newPassword })
          .type(InputType.Password).width('100%').margin({ bottom: 12 })
          .onChange((v: string) => { this.newPassword = v; })
        Button('保存修改')
          .width('100%').backgroundColor('#007AFF').borderRadius(8)
          .onClick(() => { this.changePassword(); })
      }
      .width('100%').padding(16).backgroundColor('#FFF').margin({ top: 8 })

      Button('退出登录')
        .width('90%').margin({ top: 32 })
        .backgroundColor('#FF4444').borderRadius(8)
        .onClick(() => { this.logout(); })
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}
