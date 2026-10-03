// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NzButtonModule } from 'ng-zorro-antd/button';

@Component({
  selector: 'xz-not-found',
  imports: [RouterLink, NzButtonModule],
  template: `
    <div class="xz-404">
      <img src="pet_xiaozhu.svg" alt="小筑" />
      <h1>404</h1>
      <p>小筑把这一页弄丢了，我们回值班台看看吧。</p>
      <button nz-button nzType="primary" nzSize="large" routerLink="/dashboard">返回首页</button>
    </div>
  `,
  styles: `
    .xz-404 {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 8px;
      text-align: center;
      background:
        radial-gradient(900px 420px at 50% -10%, rgba(99, 102, 241, 0.14), transparent 60%),
        var(--xz-bg-layout);
    }

    img {
      height: 180px;
      margin-bottom: 8px;
    }

    h1 {
      margin: 0;
      font-size: 48px;
      font-weight: 700;
      color: var(--xz-primary);
      font-variant-numeric: tabular-nums;
    }

    p {
      margin: 0 0 20px;
      color: var(--xz-text-secondary);
    }
  `,
})
export class NotFoundComponent {}
