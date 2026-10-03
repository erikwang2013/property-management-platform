// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzInputModule } from 'ng-zorro-antd/input';
import { NZ_MODAL_DATA, NzModalRef } from 'ng-zorro-antd/modal';

interface PasswordPromptData {
  tip: string;
}

/** 敏感操作的密码确认弹窗内容组件；确认时 `close(密码)`，取消 `close(null)` */
@Component({
  selector: 'xz-password-prompt',
  imports: [FormsModule, NzButtonModule, NzInputModule],
  template: `
    <p class="tip">{{ tip }}</p>
    <input
      nz-input
      type="password"
      placeholder="请输入登录密码"
      [(ngModel)]="password"
      (keyup.enter)="ok()"
      autofocus
    />
    <div class="actions">
      <button nz-button (click)="ref.close(null)">取消</button>
      <button nz-button nzType="primary" nzDanger [disabled]="!password" (click)="ok()">
        确认
      </button>
    </div>
  `,
  styles: `
    .tip { margin: 0 0 12px; color: var(--xz-text-secondary); }
    .actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 16px; }
  `,
})
export class PasswordPromptComponent {
  readonly ref = inject<NzModalRef<PasswordPromptComponent, string | null>>(NzModalRef);
  readonly tip =
    inject<PasswordPromptData>(NZ_MODAL_DATA, { optional: true })?.tip ??
    '该操作不可撤销，请输入登录密码确认。';
  password = '';

  ok(): void {
    this.ref.close(this.password || null);
  }
}
