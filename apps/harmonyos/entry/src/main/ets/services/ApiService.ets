/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';

const BASE_URL = 'http://10.0.2.2:8788'; // Android emulator → host; change for real device

// API 版本在接口路由中（/api/v1/*、/service/v1/*），不通过请求头传递
const VERSION = 'v1';

export class ApiService {
  private static instance: ApiService;
  private token: string = '';

  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }

  async init(): Promise<void> {
    const prefs = await preferences.getPreferences(getContext(), 'property_portal');
    this.token = (await prefs.get('access_token', '')) as string;
  }

  private getHeaders(): Object {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', 'X-Client-Platform': 'harmonyos' };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  /** 在接口路由首段后插入版本段: /service/home → /service/v1/home */
  private versioned(path: string): string {
    return BASE_URL + path.replace(/^(\/[^/]+)/, `$1/${VERSION}`);
  }

  async get(path: string): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(this.versioned(path), { method: http.RequestMethod.GET, header: this.getHeaders() });
    req.destroy();
    return JSON.parse(resp.result as string);
  }

  /**
   * 分页列表统一解包。service 端列表接口为 illuminate paginate() 线格式：
   * {code, message, data: {current_page, data: [...], total, ...}} —— 列表项在 data.data。
   */
  async getList<T>(path: string): Promise<T[]> {
    const resp = await this.get(path) as Record<string, Object>;
    if (resp['code'] !== 0) {
      return [];
    }
    const page = resp['data'] as Record<string, Object>;
    return (page['data'] as T[]) || [];
  }

  async post(path: string, data?: Object): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(this.versioned(path), {
      method: http.RequestMethod.POST,
      header: this.getHeaders(),
      extraData: JSON.stringify(data)
    });
    req.destroy();
    return JSON.parse(resp.result as string);
  }

  async put(path: string, data: Object): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(this.versioned(path), {
      method: http.RequestMethod.PUT,
      header: this.getHeaders(),
      extraData: JSON.stringify(data)
    });
    req.destroy();
    return JSON.parse(resp.result as string);
  }

  async delete(path: string): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(this.versioned(path), { method: http.RequestMethod.DELETE, header: this.getHeaders() });
    req.destroy();
    return JSON.parse(resp.result as string);
  }
}
