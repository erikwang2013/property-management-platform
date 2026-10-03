// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 验证码：image 是「整段 data URI 再做 base64」，解码一次即可直接用作 <img src>。

export interface CaptchaText {
  text: string;
  order: number;
}

export interface Captcha {
  key: string;
  /** 已解码的 data URI，可直接绑 <img [src]> */
  image: string;
  texts: CaptchaText[];
}

export interface CaptchaResponse {
  key: string;
  image: string;
  extra?: { texts?: CaptchaText[] };
}

/** 后端 image 字段解一层 base64，得到 `data:image/png;base64,...` */
export function decodeCaptchaImage(image: string): string {
  if (!image) return '';
  const decoded = atob(image);
  // 已带前缀则原样返回，避免二次拼接出 `data:image/png;base64,data:image/png;base64,...`
  return decoded.startsWith('data:') ? decoded : `data:image/png;base64,${decoded}`;
}

/**
 * 把 <img> 上的点击换算成图片原始坐标。
 * 以图片自身 natural 尺寸为准：后端画布默认 300×200，且可由 size 选项覆盖，不能写死常量。
 * naturalWidth 为 0（尚未加载完）时退化为渲染尺寸，至少不会除零。
 */
export function toImageCoords(
  event: MouseEvent,
  el: HTMLImageElement,
): { x: number; y: number } {
  const rect = el.getBoundingClientRect();
  const width = el.naturalWidth || rect.width;
  const height = el.naturalHeight || rect.height;
  return {
    x: Math.round(((event.clientX - rect.left) / rect.width) * width),
    y: Math.round(((event.clientY - rect.top) / rect.height) * height),
  };
}

export function normalizeCaptcha(res: CaptchaResponse): Captcha {
  return {
    key: res.key,
    image: decodeCaptchaImage(res.image),
    texts: [...(res.extra?.texts ?? [])].sort((a, b) => a.order - b.order),
  };
}
