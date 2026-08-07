/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import { ApiService } from './ApiService';
import { ClickPoint, LoginRequest } from '../model/Models';
import preferences from '@ohos.data.preferences';

export class AuthService {
  private api: ApiService = ApiService.getInstance();

  async login(phone: string, password: string, captchaKey: string, clicks: Array<ClickPoint>): Promise<Object> {
    const params: LoginRequest = { phone, password, captcha_key: captchaKey, clicks };
    const resp = await this.api.post('/api/auth/login', params);
    const data = resp as Record<string, Object>;
    if (data['code'] === 0) {
      const result = data['data'] as Record<string, Object>;
      const prefs = await preferences.getPreferences(getContext(), 'property_portal');
      await prefs.put('access_token', result['access_token'] as string);
      await prefs.put('refresh_token', result['refresh_token'] as string);
      await prefs.flush();
    }
    return data;
  }

  async logout(): Promise<void> {
    try { await this.api.post('/service/profile/logout'); } catch (e) {}
    const prefs = await preferences.getPreferences(getContext(), 'property_portal');
    await prefs.delete('access_token');
    await prefs.delete('refresh_token');
    await prefs.flush();
  }

  async isLoggedIn(): Promise<boolean> {
    const prefs = await preferences.getPreferences(getContext(), 'property_portal');
    const token = (await prefs.get('access_token', '')) as string;
    return token.length > 0;
  }
}
