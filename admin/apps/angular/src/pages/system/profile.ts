// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 个人中心：资料编辑（PUT /admin/profile）+ 改密（PUT /admin/profile/password）+ 登出。
// 改密后端校验与账号锁定策略一致：8-32 位，含大小写字母、数字、特殊字符 @$!%*?&。
import { Component, computed, inject, signal } from '@angular/core';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzCardModule } from 'ng-zorro-antd/card';
import { NzDescriptionsModule } from 'ng-zorro-antd/descriptions';
import { NzGridModule } from 'ng-zorro-antd/grid';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzTagModule } from 'ng-zorro-antd/tag';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { AuthService } from '../../auth/auth.service';
import { ENABLE_TAGS } from '../../api/dict';
import { ConfirmService } from '../../components/confirm.service';
import { FormModalComponent } from '../../components/form-modal/form-modal';
import { FormField, FormValue } from '../../components/types';

interface ProfileData extends Record<string, unknown> {
  id: string;
  username: string;
  real_name: string;
  avatar: string;
  email: string;
  phone: string;
  status: number;
  tenant_id: number;
  last_login_at: string | null;
  last_login_ip: string;
  created_at: string;
}

@Component({
  selector: 'xz-system-profile',
  imports: [
    FormModalComponent,
    NzButtonModule,
    NzCardModule,
    NzDescriptionsModule,
    NzGridModule,
    NzIconModule,
    NzTagModule,
  ],
  templateUrl: './profile.html',
  styleUrl: './profile.scss',
})
export class ProfileComponent {
  private readonly api = inject(ApiService);
  private readonly message = inject(NzMessageService);
  private readonly confirm = inject(ConfirmService);
  protected readonly auth = inject(AuthService);

  protected readonly profile = signal<ProfileData | null>(null);
  protected readonly loading = signal(true);
  protected readonly statusTags = ENABLE_TAGS;

  /** 只把可编辑字段交给通用弹窗（后端 updateProfile 也只接受这三个） */
  protected readonly formValues = computed<FormValue | null>(() => {
    const p = this.profile();
    return p ? { real_name: p.real_name, phone: p.phone, email: p.email } : null;
  });

  protected readonly infoOpen = signal(false);
  protected readonly pwdOpen = signal(false);

  protected readonly infoFields: FormField[] = [
    { key: 'real_name', label: '真实姓名', required: true },
    { key: 'phone', label: '手机号', hint: '数据库加密存储，列表接口不返回明文' },
    { key: 'email', label: '邮箱', hint: '数据库加密存储' },
  ];

  protected readonly pwdFields: FormField[] = [
    { key: 'old_password', label: '当前密码', kind: 'password', required: true },
    {
      key: 'new_password',
      label: '新密码',
      kind: 'password',
      required: true,
      hint: '8-32 位，需含大小写字母、数字与特殊字符（@$!%*?&）',
    },
    { key: 'confirm_password', label: '确认新密码', kind: 'password', required: true },
  ];

  constructor() {
    void this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      this.profile.set(await firstValueFrom(this.api.get<ProfileData>(API.profile)));
    } catch (err) {
      this.message.error(errorText(err));
    } finally {
      this.loading.set(false);
    }
  }

  protected readonly submitInfo = async (value: FormValue): Promise<unknown> => {
    const updated = await firstValueFrom(this.api.put<ProfileData>(API.profile, value));
    this.profile.set(updated);
    // 顶栏用户信息同步刷新
    this.auth.setUser(updated);
    return updated;
  };

  protected readonly onInfoSaved = (): void => {
    this.message.success('资料已更新');
  };

  protected readonly submitPassword = async (value: FormValue): Promise<unknown> => {
    if (value['new_password'] !== value['confirm_password']) {
      throw new Error('两次输入的新密码不一致');
    }
    return firstValueFrom(
      this.api.put(API.profilePassword, {
        old_password: value['old_password'],
        new_password: value['new_password'],
      }),
    );
  };

  protected readonly onPasswordSaved = (): void => {
    this.message.success('密码已修改，请用新密码重新登录');
    // 改密后旧 token 仍有效，但按安全惯例要求重新登录
    void this.confirm.ask('密码已修改，是否立即重新登录？', '重新登录').then((ok) => {
      if (ok) this.auth.logout();
    });
  };

  protected logout(): void {
    this.auth.logout();
  }

  protected openInfo(): void {
    this.infoOpen.set(true);
  }

  protected openPwd(): void {
    this.pwdOpen.set(true);
  }
}
