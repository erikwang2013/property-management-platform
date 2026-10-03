// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 后端所有 destroy / batch destroy 都要求登录密码二次确认，这里统一收口。
import { Injectable, inject } from '@angular/core';
import { NzModalService } from 'ng-zorro-antd/modal';
import { firstValueFrom } from 'rxjs';

import { PasswordPromptComponent } from './password-prompt';

interface PasswordPromptData {
  tip: string;
}

@Injectable({ providedIn: 'root' })
export class ConfirmService {
  private readonly modal = inject(NzModalService);

  /** 普通确认；取消返回 false */
  async ask(content: string, title = '操作确认'): Promise<boolean> {
    const ref = this.modal.confirm({ nzTitle: title, nzContent: content });
    try {
      await firstValueFrom(ref.afterClose);
      return true;
    } catch {
      return false;
    }
  }

  /** 删除类二次确认，返回登录密码；取消返回 null */
  async askPassword(content: string, title = '敏感操作确认'): Promise<string | null> {
    const ref = this.modal.create<PasswordPromptComponent, PasswordPromptData, string | null>({
      nzTitle: title,
      nzContent: PasswordPromptComponent,
      nzFooter: null,
      nzWidth: 420,
      nzData: { tip: content },
    });
    return (await firstValueFrom(ref.afterClose)) ?? null;
  }
}
