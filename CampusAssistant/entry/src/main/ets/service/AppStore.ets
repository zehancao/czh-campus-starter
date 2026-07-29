import { UserInfo } from '../model/Models';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { WebSocketService } from './WebSocketService';

export class AppStore {
  private static readonly PREF_NAME: string = 'campus_auth';
  private static readonly TOKEN_KEY: string = 'token';
  private static readonly USER_INFO_KEY: string = 'userInfo';
  private static readonly TOKEN_EXPIRES_AT_KEY: string = 'tokenExpiresAt';
  private static instance: AppStore | undefined = undefined;
  token: string = '';
  userInfo: UserInfo = new UserInfo();
  isLoggedIn: boolean = false;
  context: common.UIAbilityContext | undefined = undefined;
  pendingTab: number = -1;

  static getInstance(): AppStore {
    if (AppStore.instance === undefined) {
      AppStore.instance = new AppStore();
    }
    return AppStore.instance;
  }

  setContext(ctx: common.UIAbilityContext): void {
    this.context = ctx;
  }

  setToken(token: string): void {
    this.token = token;
    this.isLoggedIn = token.length > 0;
    AppStorage.set('appToken', token);
    AppStorage.set('appIsLoggedIn', this.isLoggedIn);
    this.saveAuthPreferences();
    if (this.isLoggedIn) {
      WebSocketService.getInstance().connect();
    }
  }

  setUserInfo(info: UserInfo): void {
    this.userInfo = info;
    AppStorage.set('appUserInfo', info);
    this.saveAuthPreferences();
  }

  restore(): void {
    if (this.context === undefined) {
      return;
    }
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(this.context, {
        name: AppStore.PREF_NAME
      });
      const token: string = pref.getSync(AppStore.TOKEN_KEY, '') as string;
      const expiresAt: number = pref.getSync(AppStore.TOKEN_EXPIRES_AT_KEY, 0) as number;
      if (token.length === 0 || (expiresAt > 0 && expiresAt <= Date.now())) {
        this.clearAuthState();
        return;
      }

      this.token = token;
      this.isLoggedIn = true;
      AppStorage.set('appToken', token);
      AppStorage.set('appIsLoggedIn', true);

      const userJson: string = pref.getSync(AppStore.USER_INFO_KEY, '') as string;
      if (userJson.length > 0) {
        this.userInfo = JSON.parse(userJson) as UserInfo;
        AppStorage.set('appUserInfo', this.userInfo);
      }
      WebSocketService.getInstance().connect();
    } catch (e) {
      this.clearAuthState();
    }
  }

  logout(): void {
    this.clearAuthState();
  }

  private clearAuthState(): void {
    WebSocketService.getInstance().disconnect();
    this.token = '';
    this.isLoggedIn = false;
    this.userInfo = new UserInfo();
    AppStorage.set('appToken', '');
    AppStorage.set('appIsLoggedIn', false);
    AppStorage.set('appUserInfo', new UserInfo());
    if (this.context !== undefined) {
      try {
        const pref: preferences.Preferences = preferences.getPreferencesSync(this.context, {
          name: AppStore.PREF_NAME
        });
        pref.deleteSync(AppStore.TOKEN_KEY);
        pref.deleteSync(AppStore.USER_INFO_KEY);
        pref.deleteSync(AppStore.TOKEN_EXPIRES_AT_KEY);
        pref.flush();
      } catch (e) {
      }
    }
  }

  private saveAuthPreferences(): void {
    if (this.context === undefined) {
      return;
    }
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(this.context, {
        name: AppStore.PREF_NAME
      });
      pref.putSync(AppStore.TOKEN_KEY, this.token);
      pref.putSync(AppStore.USER_INFO_KEY, JSON.stringify(this.userInfo));
      pref.putSync(AppStore.TOKEN_EXPIRES_AT_KEY, this.getTokenExpiresAt(this.token));
      pref.flush();
    } catch (e) {
    }
  }

  private getTokenExpiresAt(token: string): number {
    const parts: string[] = token.split('.');
    if (parts.length !== 3) {
      return 0;
    }
    try {
      let payload: string = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      while (payload.length % 4 !== 0) {
        payload += '=';
      }
      const decoded: string = this.decodeBase64(payload);
      const claims: Record<string, Object> = JSON.parse(decoded) as Record<string, Object>;
      const exp: number = claims['exp'] as number;
      return exp > 0 ? exp * 1000 : 0;
    } catch (e) {
      return 0;
    }
  }

  private decodeBase64(value: string): string {
    const alphabet: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let output: string = '';
    let buffer: number = 0;
    let bits: number = 0;
    for (let i = 0; i < value.length; i++) {
      const char: string = value[i];
      if (char === '=') {
        break;
      }
      const digit: number = alphabet.indexOf(char);
      if (digit < 0) {
        continue;
      }
      buffer = (buffer << 6) | digit;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        output += String.fromCharCode((buffer >> bits) & 0xff);
      }
    }
    return output;
  }
}
