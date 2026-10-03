// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { Component, ElementRef, inject, signal, viewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzFormModule } from 'ng-zorro-antd/form';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzInputModule } from 'ng-zorro-antd/input';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzSpinModule } from 'ng-zorro-antd/spin';
import { NzTagModule } from 'ng-zorro-antd/tag';
import { firstValueFrom } from 'rxjs';

import { API, ApiService, errorText } from '../../api/api.service';
import { AuthService } from '../../auth/auth.service';
import { Captcha, CaptchaResponse, normalizeCaptcha, toImageCoords } from '../../auth/captcha';

interface Click {
  x: number;
  y: number;
}

@Component({
  selector: 'xz-login',
  imports: [
    FormsModule,
    NzButtonModule,
    NzFormModule,
    NzIconModule,
    NzInputModule,
    NzSpinModule,
    NzTagModule,
  ],
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
export class LoginComponent {
  private readonly api = inject(ApiService);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly message = inject(NzMessageService);

  private readonly captchaImg = viewChild<ElementRef<HTMLImageElement>>('captchaImg');

  protected username = '';
  protected password = '';
  protected readonly captcha = signal<Captcha | null>(null);
  protected readonly clicks = signal<Click[]>([]);
  protected readonly loadingCaptcha = signal(false);
  protected readonly submitting = signal(false);
  /** 表单级错误提示（含验证码失败 / 账号锁定提示） */
  protected readonly formError = signal('');

  constructor() {
    void this.loadCaptcha();
  }

  /** 提示行：文案与 React 同句（team-lead 2026-10-03 裁定跟 React —— 一次看全比逐个揭示好）。
   *  具体要点的字在下方编号 chips 里全列，这里不再逐个揭示。 */
  protected currentPrompt(): string {
    const c = this.captcha();
    if (!c || c.texts.length === 0) return '正在加载验证码…';
    if (this.clicks().length >= c.texts.length) return '已完成点击，可登录';
    return '请依次点击验证码上的文字';
  }

  /** 编号 chips 的档位（与 React 的 gold/green/default 同义，落到本设计色板的三档）：
   *  已点 success · 当前 warning · 未到 default */
  protected hintTone(index: number): string {
    const done = this.clicks().length;
    if (index < done) return 'success';
    return index === done ? 'warning' : 'default';
  }

  protected readonly clickHint = () => {
    const c = this.captcha();
    if (!c) return '';
    const done = this.clicks()
      .map((_, i) => c.texts[i]?.text)
      .filter(Boolean);
    return done.length ? `已点：${done.join(' → ')}` : '';
  };

  async loadCaptcha(): Promise<void> {
    this.loadingCaptcha.set(true);
    this.formError.set('');
    try {
      const res = await firstValueFrom(
        this.api.post<CaptchaResponse>(API.captchaGenerate, { difficulty: 'medium' }),
      );
      this.captcha.set(normalizeCaptcha(res));
      this.clicks.set([]);
    } catch (err) {
      this.formError.set(errorText(err));
    } finally {
      this.loadingCaptcha.set(false);
    }
  }

  /**
   * 验证码真实画布尺寸：由图片 natural 尺寸决定（后端默认 300×200，可被 size 选项覆盖）。
   * 点击换算与标记定位共用这一个来源，不再各写一份常量。
   */
  protected readonly canvasSize = signal({ w: 0, h: 0 });

  protected onCaptchaLoad(event: Event): void {
    const img = event.target as HTMLImageElement;
    this.canvasSize.set({ w: img.naturalWidth, h: img.naturalHeight });
  }

  /** 在验证码图上点击：换算成画布原始坐标并记录 */
  onCaptchaClick(event: MouseEvent): void {
    const img = this.captchaImg()?.nativeElement;
    const c = this.captcha();
    if (!img || !c) return;
    if (this.clicks().length >= c.texts.length) {
      this.message.info('已点满，如需重来请刷新验证码');
      return;
    }
    this.clicks.update((list) => [...list, toImageCoords(event, img)]);
  }

  protected undoClick(): void {
    this.clicks.update((list) => list.slice(0, -1));
  }

  protected canSubmit(): boolean {
    const c = this.captcha();
    return (
      !!this.username &&
      !!this.password &&
      !!c &&
      this.clicks().length === c.texts.length &&
      !this.submitting()
    );
  }

  /** 只接受站内相对路径，挡住 `?redirect=https://evil` 这类开放重定向 */
  private safeRedirect(): string {
    const raw = new URLSearchParams(location.search).get('redirect') ?? '';
    return raw.startsWith('/') && !raw.startsWith('//') ? raw : '/dashboard';
  }

  async submit(): Promise<void> {
    const c = this.captcha();
    if (!c) return;
    this.submitting.set(true);
    this.formError.set('');
    try {
      await firstValueFrom(
        this.auth.login({
          username: this.username,
          password: this.password,
          captcha_key: c.key,
          clicks: this.clicks(),
        }),
      );
      this.message.success('登录成功');
      await this.router.navigateByUrl(this.safeRedirect());
    } catch (err) {
      this.formError.set(errorText(err));
      // 验证码一次性，失败后必须刷新
      await this.loadCaptcha();
    } finally {
      this.submitting.set(false);
    }
  }
}
