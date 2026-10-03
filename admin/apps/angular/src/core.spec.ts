// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 覆盖「出错了很难查」的非平凡逻辑：
//   1. 响应包解包（code !== 0 抛错，且兼容 {msg} 与 {message} 两种键）
//   2. 根注入器能解析共享服务 + 13 个路由页面逐个能创建（NG0201 那类运行期崩溃，
//      编译期与既有单测都发现不了，只能靠真的把页面渲染一遍）
//   3. 验证码 image 的 data URI 二次编码解码
//   4. 401 刷新排队（并发 401 只触发一次刷新，其余请求等刷新后重放）
import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { ApplicationRef, Type } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideNoopAnimations } from '@angular/platform-browser/animations';
import { Subject } from 'rxjs';

import { NzModalService } from 'ng-zorro-antd/modal';

import { ApiError, ApiService } from './api/api.service';
import { appConfig } from './app.config';
import { routes } from './app.routes';
import { authInterceptor } from './auth/auth.interceptor';
import { AuthService } from './auth/auth.service';
import { decodeCaptchaImage, normalizeCaptcha, toImageCoords } from './auth/captcha';
import { ConfirmService } from './components/confirm.service';
import { DateValueCache } from './components/date-value';
import { FormModalComponent } from './components/form-modal/form-modal';
import { FormField } from './components/types';

describe('响应包解包 ApiService.unwrap', () => {
  let api: ApiService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient()] });
    api = TestBed.inject(ApiService);
  });

  it('code === 0 时返回 data', () => {
    expect(api.unwrap({ code: 0, message: '', data: { id: 'abc' } })).toEqual({ id: 'abc' });
  });

  it('code !== 0 抛 ApiError，并带上 code 与 message', () => {
    expect(() => api.unwrap({ code: 422, message: '账单金额必须大于0', data: null })).toThrowError(
      ApiError,
    );
    try {
      api.unwrap({ code: 422, message: '账单金额必须大于0', data: null });
    } catch (err) {
      expect((err as ApiError).code).toBe(422);
      expect((err as ApiError).message).toBe('账单金额必须大于0');
    }
  });

  it('框架级异常只有 msg 键时也能取到文案', () => {
    // 非法 hashid 走的是 {code:500,msg}，没有 message 键
    try {
      api.unwrap({ code: 500, msg: '无效的ID', data: null });
      fail('应当抛错');
    } catch (err) {
      expect((err as ApiError).message).toBe('无效的ID');
    }
  });

  it('既无 message 也无 msg 时给兜底文案', () => {
    try {
      api.unwrap({ code: 500, data: null });
      fail('应当抛错');
    } catch (err) {
      expect((err as ApiError).message).toBe('请求失败');
    }
  });
});

describe('根注入器能解析共享服务（NG0201 回归守卫）', () => {
  // 曾经的事故：NzModalService 的 ɵprov 没有 providedIn，只由 NzModalModule 提供；
  // ConfirmService 是 providedIn:'root' 且在根作用域 inject 它，于是按需加载的 9 个页面
  // 全部在组件构造期抛 NG0201、正文空白且一个接口都不发。编译期完全发现不了。
  it('app.config 的 providers 能让 ConfirmService 在根作用域解析', () => {
    TestBed.configureTestingModule({ providers: [...appConfig.providers] });
    expect(() => TestBed.inject(ConfirmService)).not.toThrow();
  });

  it('NzModalService 本身也能在根作用域解析', () => {
    TestBed.configureTestingModule({ providers: [...appConfig.providers] });
    expect(() => TestBed.inject(NzModalService)).not.toThrow();
  });
});

describe('路由页面冒烟：逐个创建 + 首次变更检测', () => {
  // 抓的是「构建通过、一渲染就崩」这类只在运行期暴露的问题 —— NG0201 那次
  // 编译期零提示、`pnpm build` 与既有单测全绿，却让 8 个按需加载页面正文空白。
  //
  // 页面清单**直接来自真实路由表**：新增路由自动纳入覆盖，不需要手工维护一份会过期的数组。
  interface LazyRoute {
    path?: string;
    loadComponent?: () => Promise<Type<unknown>>;
    children?: LazyRoute[];
  }

  function collect(list: LazyRoute[], prefix = ''): { path: string; load: () => Promise<Type<unknown>> }[] {
    const out: { path: string; load: () => Promise<Type<unknown>> }[] = [];
    for (const r of list) {
      const path = [prefix, r.path ?? ''].filter((s) => s !== '').join('/');
      if (r.loadComponent) out.push({ path: `/${path}`, load: r.loadComponent });
      if (r.children?.length) out.push(...collect(r.children, path));
    }
    return out;
  }

  const pages = collect(routes as unknown as LazyRoute[]);

  beforeEach(() => {
    // 刻意用 app.config 的真实 providers（而不是在这里另抄一份）：被测的正是
    // 「根注入器提供的东西够不够页面构造期用」。补 testing backend 挡住真实请求。
    TestBed.configureTestingModule({
      providers: [...appConfig.providers, provideHttpClientTesting()],
    });
  });

  it('路由表里至少 16 个懒加载页面（防止上面那个 collect 被改空后一路绿灯）', () => {
    expect(pages.length).toBeGreaterThanOrEqual(16);
  });

  for (const { path, load } of pages) {
    it(`${path} 能创建并完成首次变更检测`, async () => {
      const type = await load();
      let fixture: ComponentFixture<unknown> | undefined;
      // createComponent 里跑构造函数（NG0201 就抛在这一步），detectChanges 跑模板
      expect(() => {
        fixture = TestBed.createComponent(type);
        fixture.detectChanges();
      }).not.toThrow();
      // 渲染出内容才算过：那次的直接表现正是正文空白
      const el = fixture?.nativeElement as HTMLElement | undefined;
      expect((el?.textContent ?? '').trim().length).toBeGreaterThan(0);
      fixture?.destroy();
    });
  }
});

describe('交互冒烟：日期控件（变更检测期才会炸的那一类）', () => {
  // 上面那组「建了就断言」的冒烟**抓不到交互期崩溃**，这条 P0 是活证：`pnpm build` 绿、
  // 单元测试绿、挂载冒烟绿，可一旦打开「带日期的编辑弹窗」主线程就被变更检测自循环饿死。
  // 根因是 NG-ZORRO 的日期控件内部走 Angular `formatDate(date, fmt, 'zh-cn')`，而工程里
  // 从没注册过中文语言数据（NG0701）；注册点必须留在 app.config.ts，测试才吃得到。
  const FIELDS: FormField[] = [
    { key: 'due_date', label: '截止日期', kind: 'date' },
    { key: 'amount', label: '金额', kind: 'number' },
  ];

  beforeEach(() => {
    TestBed.configureTestingModule({
      // 依旧用真实 appConfig（被测的正是它注册语言数据这件事），只把动画换成 noop 以便驱动 overlay
      providers: [...appConfig.providers, provideHttpClientTesting(), provideNoopAnimations()],
    });
  });

  /** 推若干轮 CD 并等稳定：弹窗与日期面板都由 cdk overlay 挂到 ApplicationRef 上，不在 fixture 的视图树里，
   *  只同步 detectChanges 的话 ng-zorro 内部的输入框来不及跟着值刷新（await whenStable 才会再跑一轮）。 */
  async function settle(fixture: ComponentFixture<unknown>, rounds = 2): Promise<void> {
    for (let i = 0; i < rounds; i++) {
      fixture.detectChanges();
      TestBed.inject(ApplicationRef).tick();
      await fixture.whenStable();
    }
  }

  async function mountEdit(): Promise<ComponentFixture<FormModalComponent>> {
    const fixture = TestBed.createComponent(FormModalComponent);
    fixture.componentRef.setInput('title', '编辑账单');
    fixture.componentRef.setInput('fields', FIELDS);
    // 日期字段带初值 —— 正是 P0 的触发条件（初值为空串时 null === null，身份不变、环起不来，
    // 所以「日期为空」的老用例全绿，只有带初值才炸）
    fixture.componentRef.setInput('values', { due_date: '2026-10-15', amount: 1200.5 });
    fixture.componentRef.setInput('submit', () => Promise.resolve(null));
    fixture.componentRef.setInput('open', true);
    // 缺中文语言数据时（writeValue → formatDate(..., 'zh-cn')）这里抛 NG0701；
    // ngModel 绑定若每次 CD 返回新 Date 身份，这里会自循环、永远不返回 —— 两种都过不去。
    await settle(fixture);
    return fixture;
  }

  /** 表单值（成员是 protected，测试里结构化读一遍） */
  function formValue(fixture: ComponentFixture<FormModalComponent>): Record<string, unknown> {
    return (fixture.componentInstance as unknown as { form: { value: Record<string, unknown> } })
      .form.value;
  }

  /** 弹窗内容渲染在 cdk overlay（document.body）里，不在 fixture 的视图树内，只能从 document 取 */
  function pickerInput(): HTMLInputElement {
    const el = document.querySelector('.ant-picker-input input') as HTMLInputElement | null;
    expect(el).not.toBeNull();
    return el!;
  }

  // 「自循环」那一半在单元测试里复现不出来：TestBed 没有 zone 持续驱动 CD，模板方法返回新对象
  // 也只会多跑几轮、不会饿死主线程（浏览器里会：verifier 的 CDP 探针 8×4s 全部超时）。
  // 所以自循环的回归守卫落在**不变量**上 —— 缓存被摘掉这条立刻红。
  it('同一原始值必须返回同一个 Date 实例（返回新对象 = 每轮 CD 都重推 = 浏览器里自循环）', () => {
    const cache = new DateValueCache();
    const first = cache.get('due_date', '2026-10-15');
    expect(cache.get('due_date', '2026-10-15')).toBe(first); // 同一串 → 同一实例
    expect(first).toBeInstanceOf(Date);
    const other = cache.get('due_date', '2026-10-16');
    expect(other).not.toBe(first); // 值真变了才换对象
    const empty = cache.get('due_date', '');
    expect(empty).toBeNull();
    expect(cache.get('due_date', '')).toBeNull(); // 空值也稳定，不能每次都 new Date('')
  });

  it('编辑态日期有初值：弹窗渲染出该日期（NG0701 / 自循环都过不了这一关）', async () => {
    const fixture = await mountEdit();
    expect(pickerInput().value).toBe('2026-10-15');
    fixture.destroy();
  });

  it('点开面板并选中一个日期 → 表单值更新、输入框跟着变', async () => {
    const fixture = await mountEdit();
    pickerInput().click(); // 真实路径：点输入框开面板
    await settle(fixture);

    const dropdown = document.querySelector('.ant-picker-dropdown');
    expect(dropdown).not.toBeNull();

    // 面板标题本身就是本地化产物（'2026年 10月'）—— 顺带证明中文语言数据在位
    const header = (dropdown!.querySelector('.ant-picker-header-view')?.textContent ?? '').replace(
      /\s+/g,
      '',
    );
    const ym = header.match(/(\d{4})年(\d{1,2})月/);
    expect(ym).not.toBeNull();

    const cells = Array.from(
      dropdown!.querySelectorAll<HTMLElement>(
        'td.ant-picker-cell-in-view:not(.ant-picker-cell-disabled)',
      ),
    );
    expect(cells.length).toBeGreaterThan(0);
    const cell = cells.find((c) => (c.textContent ?? '').trim() === '8') ?? cells[0];
    const day = (cell.textContent ?? '').trim();
    cell.click();
    await settle(fixture);

    const pad = (n: string) => n.padStart(2, '0');
    const expected = `${ym![1]}-${pad(ym![2])}-${pad(day)}`;
    expect(formValue(fixture)['due_date']).toBe(expected); // 选中 → ngModelChange → 表单
    expect(pickerInput().value).toBe(expected); // 表单 → 再写回输入框
    fixture.destroy();
  });
});

describe('验证码 image 的 data URI 解码', () => {
  /** 后端把「整段 data URI」再 base64 一次，前端只需解一层 */
  const rawPng = 'iVBORw0KGgoAAAANSUhEUg==';

  it('解一层后补 data URI 前缀', () => {
    expect(decodeCaptchaImage(btoa(rawPng))).toBe(`data:image/png;base64,${rawPng}`);
  });

  it('已经是 data URI 时原样返回，不会二次拼接出 data:...data:...', () => {
    const already = `data:image/png;base64,${rawPng}`;
    const decoded = decodeCaptchaImage(btoa(already));
    expect(decoded).toBe(already);
    expect(decoded.match(/data:image\/png;base64,/g)?.length).toBe(1);
  });

  it('空串返回空串（不抛 atob 异常）', () => {
    expect(decodeCaptchaImage('')).toBe('');
  });

  it('normalizeCaptcha 按 order 排序后给出可直接渲染的 src', () => {
    const captcha = normalizeCaptcha({
      key: 'k1',
      image: btoa(rawPng),
      extra: {
        texts: [
          { text: '园', order: 3 },
          { text: '花', order: 1 },
          { text: '小', order: 2 },
        ],
      },
    });
    expect(captcha.image).toBe(`data:image/png;base64,${rawPng}`);
    expect(captcha.texts.map((t) => t.text)).toEqual(['花', '小', '园']);
  });

  /** 造一个「渲染尺寸 ≠ natural 尺寸」的 img，用来证明换算依据的是后者 */
  function fakeImg(rendered: { w: number; h: number }, natural: { w: number; h: number }) {
    return {
      getBoundingClientRect: () =>
        ({ left: 0, top: 0, width: rendered.w, height: rendered.h }) as DOMRect,
      naturalWidth: natural.w,
      naturalHeight: natural.h,
    } as unknown as HTMLImageElement;
  }

  it('toImageCoords 按 natural 尺寸换算，而不是写死的画布常量', () => {
    // 后端画布 300×200，被压到 150×100 显示；点显示中心 → 原始坐标 (150, 100)
    const el = fakeImg({ w: 150, h: 100 }, { w: 300, h: 200 });
    expect(toImageCoords({ clientX: 75, clientY: 50 } as MouseEvent, el)).toEqual({ x: 150, y: 100 });
  });

  it('画布尺寸被后端 size 选项改掉时同样成立（480×320）', () => {
    const el = fakeImg({ w: 240, h: 160 }, { w: 480, h: 320 });
    expect(toImageCoords({ clientX: 240, clientY: 160 } as MouseEvent, el)).toEqual({ x: 480, y: 320 });
  });

  it('图片尚未加载（natural 为 0）时退化为渲染尺寸，不产生 NaN', () => {
    const el = fakeImg({ w: 300, h: 200 }, { w: 0, h: 0 });
    const coords = toImageCoords({ clientX: 150, clientY: 100 } as MouseEvent, el);
    expect(coords).toEqual({ x: 150, y: 100 });
  });
});

describe('401 刷新排队 authInterceptor', () => {
  let http: HttpClient;
  let httpMock: HttpTestingController;
  let refresh$: Subject<string>;
  let refreshCalls: number;
  let sessionExpiredCalls: number;

  beforeEach(() => {
    refresh$ = new Subject<string>();
    refreshCalls = 0;
    sessionExpiredCalls = 0;

    // 只实现拦截器真正用到的三处：读 token / 刷新 / 会话失效
    const authStub = {
      accessToken: () => 'old-token',
      refresh: () => {
        refreshCalls += 1;
        return refresh$;
      },
      sessionExpired: () => {
        sessionExpiredCalls += 1;
      },
    };

    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
        { provide: AuthService, useValue: authStub },
      ],
    });
    http = TestBed.inject(HttpClient);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    // shareReplay 在源 complete 时才跑 finalize；不补这一刀会留下模块级在途刷新，污染下一个用例
    refresh$.complete();
    httpMock.verify();
  });

  /** AdminAuth 中间件的 401 是 HTTP 200 + body.code 401，不是 HTTP 401 */
  it('body.code === 401 会被识别为未登录并触发刷新', () => {
    http.get('/admin/community').subscribe({ error: () => void 0 });

    const req = httpMock.expectOne('/admin/community');
    expect(req.request.headers.get('Authorization')).toBe('Bearer old-token');
    req.flush({ code: 401, message: '未登录', data: [] });

    // 刷新还没返回，此时不应有重放请求
    expect(refreshCalls).toBe(1);
    httpMock.expectNone('/admin/community');
  });

  it('两个并发请求同时 401，只刷新一次，刷新后都用新 token 重放', () => {
    const seen: string[] = [];
    http.get('/admin/community').subscribe(() => seen.push('a'));
    http.get('/admin/owner').subscribe(() => seen.push('b'));

    httpMock.expectOne('/admin/community').flush({ code: 401, message: '未登录', data: [] });
    httpMock.expectOne('/admin/owner').flush({ code: 401, message: '未登录', data: [] });

    // 两次 401 共用同一次在途刷新
    expect(refreshCalls).toBe(1);
    expect(sessionExpiredCalls).toBe(0);

    refresh$.next('new-token');

    const replayed = httpMock.match(() => true);
    expect(replayed.length).toBe(2);
    for (const r of replayed) {
      expect(r.request.headers.get('Authorization')).toBe('Bearer new-token');
      r.flush({ code: 0, message: 'ok', data: { ok: true } });
    }
    expect(seen.length).toBe(2);
  });

  it('刷新失败时视为会话过期，不再重放', () => {
    let errored = false;
    http.get('/admin/community').subscribe({ error: () => (errored = true) });

    httpMock.expectOne('/admin/community').flush({ code: 401, message: '未登录', data: [] });
    expect(refreshCalls).toBe(1);

    refresh$.error(new Error('refresh failed'));

    expect(errored).toBe(true);
    expect(sessionExpiredCalls).toBe(1);
  });

  it('重放后仍然 401 则直接登出（不进入刷新死循环）', () => {
    http.get('/admin/community').subscribe({ error: () => void 0 });

    httpMock.expectOne('/admin/community').flush({ code: 401, message: '未登录', data: [] });
    refresh$.next('new-token');

    const replayed = httpMock.expectOne('/admin/community');
    expect(replayed.request.headers.get('Authorization')).toBe('Bearer new-token');
    replayed.flush({ code: 401, message: '未登录', data: [] });

    expect(refreshCalls).toBe(1); // 没有再触发第二次刷新
    expect(sessionExpiredCalls).toBe(1);
  });
});
