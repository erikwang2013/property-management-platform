// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { NgTemplateOutlet } from '@angular/common';
import { Component, DestroyRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterLink, RouterOutlet } from '@angular/router';
import { NzButtonModule } from 'ng-zorro-antd/button';
import { NzDrawerModule } from 'ng-zorro-antd/drawer';
import { NzDropDownModule } from 'ng-zorro-antd/dropdown';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzLayoutModule } from 'ng-zorro-antd/layout';
import { NzMenuModule } from 'ng-zorro-antd/menu';
import { filter } from 'rxjs';

import { AuthService } from '../auth/auth.service';
import { NAV } from './menu';

@Component({
  selector: 'xz-layout',
  imports: [
    NgTemplateOutlet,
    RouterLink,
    RouterOutlet,
    NzButtonModule,
    NzDrawerModule,
    NzDropDownModule,
    NzIconModule,
    NzLayoutModule,
    NzMenuModule,
  ],
  templateUrl: './layout.html',
  styleUrl: './layout.scss',
})
export class LayoutComponent {
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly auth = inject(AuthService);
  protected readonly nav = NAV;
  protected readonly title = signal('物业管理平台');
  /** 当前路径（signal 版，菜单选中态需要随导航更新） */
  protected readonly currentUrl = signal('/');

  protected readonly collapsed = signal(matchMedia('(max-width: 991px)').matches);
  protected readonly isMobile = signal(matchMedia('(max-width: 767px)').matches);
  protected readonly drawerOpen = signal(false);

  constructor() {
    this.bindMedia('(max-width: 991px)', (m) => this.collapsed.set(m));
    this.bindMedia('(max-width: 767px)', (m) => {
      this.isMobile.set(m);
      if (!m) this.drawerOpen.set(false);
    });
    this.router.events
      .pipe(
        filter((e): e is NavigationEnd => e instanceof NavigationEnd),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe(() => {
        this.currentUrl.set(this.router.url.split('?')[0]);
        this.title.set(this.titleOf(this.currentUrl()));
        this.drawerOpen.set(false);
      });
  }

  private bindMedia(query: string, apply: (matches: boolean) => void): void {
    const mql = matchMedia(query);
    apply(mql.matches);
    const handler = (e: MediaQueryListEvent) => apply(e.matches);
    mql.addEventListener('change', handler);
    this.destroyRef.onDestroy(() => mql.removeEventListener('change', handler));
  }

  private titleOf(url: string): string {
    const path = url.split('?')[0];
    for (const group of NAV) {
      for (const item of group.items) {
        if (item.path === path) return item.label;
      }
    }
    return '物业管理平台';
  }

  protected isActive(path: string): boolean {
    const url = this.currentUrl();
    if (path === '/system') return url === '/system';
    return url === path || url.startsWith(path + '/');
  }

  protected toggle(): void {
    if (this.isMobile()) this.drawerOpen.update((v) => !v);
    else this.collapsed.update((v) => !v);
  }

  protected logout(): void {
    this.auth.logout();
  }
}
