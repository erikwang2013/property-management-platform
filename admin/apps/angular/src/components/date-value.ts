// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 日期控件的 ngModel 取值缓存 —— 不是性能优化，是**防死循环**，改动前务必读完这段注释。
//
// 背景：表单/筛选控件里存的是 `'YYYY-MM-DD'` 字符串，而 nz-date-picker / nz-range-picker 的
// ngModel 要的是 `Date`，所以模板写的是 `[ngModel]="dateValue(key)"`（方法绑定）。
//
// 方法绑定会在**每次变更检测**重新求值。若每次都 `new Date(raw)`，返回的是**新对象**：
// NgModel 按身份比较判定「值变了」→ 推送进控件 → 控件的 `writeValue()` 里有一句
// `cdr.markForCheck()` → 调度下一轮 CD → 模板再求值 → 又一个新对象 → …
// **自循环**，主线程被彻底饿死（页面冻死、CDP evaluate 超时、console 事件也停止投递）。
//
// 实测（verifier 2026-10-03 P0）：`/fee-bills` 编辑一行**日期字段有初值**的账单 → 整页卡死；
// 同一脚本把初值换成空串就正常 —— 空串走 `null` 分支，`null === null` 身份不变，环起不来。
//
// 药方：同一个原始字符串复用同一个 Date 实例，身份稳定 → NgModel 第二次 CD 就不再推送 → 断环。
export class DateValueCache {
  private readonly cache = new Map<string, { raw: string; date: Date }>();

  /**
   * @param key 字段名（同一控件内同名即同一个缓存槽；不同表单实例各自持有一份缓存，不串）
   * @param raw 控件当前值（字符串；空值返回 null）
   */
  get(key: string, raw: unknown): Date | null {
    const text = raw === null || raw === undefined ? '' : String(raw);
    if (!text) return null;
    const hit = this.cache.get(key);
    if (hit && hit.raw === text) return hit.date;
    const date = new Date(text);
    this.cache.set(key, { raw: text, date });
    return date;
  }
}
