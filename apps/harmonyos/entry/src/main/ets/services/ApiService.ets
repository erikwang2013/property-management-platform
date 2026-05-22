/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';

const BASE_URL = 'http://10.0.2.2:8788'; // Android emulator → host; change for real device

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
    this.token = prefs.get('access_token', '') as string;
  }

  private getHeaders(): Object {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', 'X-Client-Platform': 'harmonyos' };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  async get(path: string): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(BASE_URL + path, { method: http.RequestMethod.GET, header: this.getHeaders() });
    req.destroy();
    return JSON.parse(resp.result as string);
  }

  async post(path: string, data: Object): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(BASE_URL + path, {
      method: http.RequestMethod.POST,
      header: this.getHeaders(),
      extraData: JSON.stringify(data)
    });
    req.destroy();
    return JSON.parse(resp.result as string);
  }

  async put(path: string, data: Object): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(BASE_URL + path, {
      method: http.RequestMethod.PUT,
      header: this.getHeaders(),
      extraData: JSON.stringify(data)
    });
    req.destroy();
    return JSON.parse(resp.result as string);
  }

  async delete(path: string): Promise<Object> {
    const req = http.createHttp();
    const resp = await req.request(BASE_URL + path, { method: http.RequestMethod.DELETE, header: this.getHeaders() });
    req.destroy();
    return JSON.parse(resp.result as string);
  }
}
