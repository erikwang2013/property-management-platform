if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface LoginPage_Params {
    username?: string;
    password?: string;
    isLoading?: boolean;
    showPassword?: boolean;
    captchaData?: CaptchaData | null;
    captchaLoading?: boolean;
    clicks?: ClickPoint[];
    clickMarkers?: ClickMarker[];
    captchaError?: string;
    loginError?: string;
    httpClient?: http.HttpRequest;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import http from "@ohos:net.http";
import { TokenManager } from "@bundle:xyz.erik.openadmin/entry/ets/utils/TokenManager";
// 开发环境地址 — 真机部署时修改为实际服务器地址
// 模拟器: http://10.0.2.2:8787
// 真机: http://<服务器IP>:8787
const BASE_URL = 'http://10.0.2.2:8787';
interface CaptchaTarget {
    order: number;
    text: string;
    x: number;
    y: number;
}
interface CaptchaData {
    key: string;
    image: string; // base64
    targets: CaptchaTarget[];
}
interface ClickPoint {
    x: number;
    y: number;
}
interface ClickMarker {
    x: number;
    y: number;
    order: number;
}
class LoginPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__username = new ObservedPropertySimplePU('', this, "username");
        this.__password = new ObservedPropertySimplePU('', this, "password");
        this.__isLoading = new ObservedPropertySimplePU(false, this, "isLoading");
        this.__showPassword = new ObservedPropertySimplePU(false, this, "showPassword");
        this.__captchaData = new ObservedPropertyObjectPU(null, this, "captchaData");
        this.__captchaLoading = new ObservedPropertySimplePU(true, this, "captchaLoading");
        this.__clicks = new ObservedPropertyObjectPU([], this, "clicks");
        this.__clickMarkers = new ObservedPropertyObjectPU([], this, "clickMarkers");
        this.__captchaError = new ObservedPropertySimplePU('', this, "captchaError");
        this.__loginError = new ObservedPropertySimplePU('', this, "loginError");
        this.httpClient = http.createHttp();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: LoginPage_Params) {
        if (params.username !== undefined) {
            this.username = params.username;
        }
        if (params.password !== undefined) {
            this.password = params.password;
        }
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
        if (params.showPassword !== undefined) {
            this.showPassword = params.showPassword;
        }
        if (params.captchaData !== undefined) {
            this.captchaData = params.captchaData;
        }
        if (params.captchaLoading !== undefined) {
            this.captchaLoading = params.captchaLoading;
        }
        if (params.clicks !== undefined) {
            this.clicks = params.clicks;
        }
        if (params.clickMarkers !== undefined) {
            this.clickMarkers = params.clickMarkers;
        }
        if (params.captchaError !== undefined) {
            this.captchaError = params.captchaError;
        }
        if (params.loginError !== undefined) {
            this.loginError = params.loginError;
        }
        if (params.httpClient !== undefined) {
            this.httpClient = params.httpClient;
        }
    }
    updateStateVars(params: LoginPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__username.purgeDependencyOnElmtId(rmElmtId);
        this.__password.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__showPassword.purgeDependencyOnElmtId(rmElmtId);
        this.__captchaData.purgeDependencyOnElmtId(rmElmtId);
        this.__captchaLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__clicks.purgeDependencyOnElmtId(rmElmtId);
        this.__clickMarkers.purgeDependencyOnElmtId(rmElmtId);
        this.__captchaError.purgeDependencyOnElmtId(rmElmtId);
        this.__loginError.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__username.aboutToBeDeleted();
        this.__password.aboutToBeDeleted();
        this.__isLoading.aboutToBeDeleted();
        this.__showPassword.aboutToBeDeleted();
        this.__captchaData.aboutToBeDeleted();
        this.__captchaLoading.aboutToBeDeleted();
        this.__clicks.aboutToBeDeleted();
        this.__clickMarkers.aboutToBeDeleted();
        this.__captchaError.aboutToBeDeleted();
        this.__loginError.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __username: ObservedPropertySimplePU<string>;
    get username() {
        return this.__username.get();
    }
    set username(newValue: string) {
        this.__username.set(newValue);
    }
    private __password: ObservedPropertySimplePU<string>;
    get password() {
        return this.__password.get();
    }
    set password(newValue: string) {
        this.__password.set(newValue);
    }
    private __isLoading: ObservedPropertySimplePU<boolean>;
    get isLoading() {
        return this.__isLoading.get();
    }
    set isLoading(newValue: boolean) {
        this.__isLoading.set(newValue);
    }
    private __showPassword: ObservedPropertySimplePU<boolean>;
    get showPassword() {
        return this.__showPassword.get();
    }
    set showPassword(newValue: boolean) {
        this.__showPassword.set(newValue);
    }
    // 验证码状态
    private __captchaData: ObservedPropertyObjectPU<CaptchaData | null>;
    get captchaData() {
        return this.__captchaData.get();
    }
    set captchaData(newValue: CaptchaData | null) {
        this.__captchaData.set(newValue);
    }
    private __captchaLoading: ObservedPropertySimplePU<boolean>;
    get captchaLoading() {
        return this.__captchaLoading.get();
    }
    set captchaLoading(newValue: boolean) {
        this.__captchaLoading.set(newValue);
    }
    private __clicks: ObservedPropertyObjectPU<ClickPoint[]>;
    get clicks() {
        return this.__clicks.get();
    }
    set clicks(newValue: ClickPoint[]) {
        this.__clicks.set(newValue);
    }
    private __clickMarkers: ObservedPropertyObjectPU<ClickMarker[]>;
    get clickMarkers() {
        return this.__clickMarkers.get();
    }
    set clickMarkers(newValue: ClickMarker[]) {
        this.__clickMarkers.set(newValue);
    }
    private __captchaError: ObservedPropertySimplePU<string>;
    get captchaError() {
        return this.__captchaError.get();
    }
    set captchaError(newValue: string) {
        this.__captchaError.set(newValue);
    }
    private __loginError: ObservedPropertySimplePU<string>;
    get loginError() {
        return this.__loginError.get();
    }
    set loginError(newValue: string) {
        this.__loginError.set(newValue);
    }
    private httpClient: http.HttpRequest;
    aboutToAppear(): void {
        this.loadCaptcha();
    }
    async loadCaptcha(): Promise<void> {
        this.captchaLoading = true;
        this.clicks = [];
        this.clickMarkers = [];
        this.captchaError = '';
        try {
            const resp = await this.httpClient.request(`${BASE_URL}/api/captcha/generate`, {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json', 'API-Version': 'v1', 'X-Client-Platform': 'harmonyos' },
                extraData: JSON.stringify({ difficulty: 'medium' }),
                connectTimeout: 10000,
                readTimeout: 10000
            });
            const result = JSON.parse(resp.result as string) as Record<string, Object>;
            if (result['code'] === 0) {
                this.captchaData = result['data'] as CaptchaData;
                this.captchaData!.targets.sort((a, b) => a.order - b.order);
            }
            else {
                this.captchaError = '验证码加载失败';
            }
        }
        catch (e) {
            this.captchaError = '网络错误，无法加载验证码';
        }
        finally {
            this.captchaLoading = false;
        }
    }
    onCaptchaClick(event: ClickEvent): void {
        if (!this.captchaData || this.clicks.length >= this.captchaData.targets.length)
            return;
        // 点击坐标 (相对于组件)
        const widgetW = 400; // 组件近似宽度
        const widgetH = 250;
        const imgW = 400;
        const imgH = 250;
        const scaleX = imgW / widgetW;
        const scaleY = imgH / widgetH;
        const imgX = Math.round(event.x * scaleX);
        const imgY = Math.round(event.y * scaleY);
        const order = this.clicks.length;
        this.clicks.push({ x: imgX, y: imgY });
        this.clickMarkers.push({ x: event.x, y: event.y, order: order + 1 });
        this.captchaError = '';
        this.loginError = '';
    }
    async login(): Promise<void> {
        const trimmedUsername = this.username.trim();
        if (!trimmedUsername) {
            this.loginError = '请输入用户名';
            return;
        }
        if (!this.password) {
            this.loginError = '请输入密码';
            return;
        }
        if (!this.captchaData || this.clicks.length < this.captchaData.targets.length) {
            const next = this.captchaData?.targets[this.clicks.length];
            this.loginError = next ? `请点击图中文字『${next.text}』` : '请完成验证码验证';
            return;
        }
        this.isLoading = true;
        this.loginError = '';
        try {
            const resp = await this.httpClient.request(`${BASE_URL}/api/auth/login`, {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json', 'API-Version': 'v1', 'X-Client-Platform': 'harmonyos' },
                extraData: JSON.stringify({
                    username: trimmedUsername,
                    password: this.password,
                    captcha_key: this.captchaData!.key,
                    clicks: this.clicks
                }),
                connectTimeout: 15000,
                readTimeout: 15000
            });
            const result = JSON.parse(resp.result as string) as Record<string, Object>;
            if (result['code'] === 0) {
                const tokenData = result['data'] as Record<string, Object>;
                await TokenManager.saveTokens(tokenData['access_token'] as string, tokenData['refresh_token'] as string);
                AppStorage.setOrCreate('adminUsername', trimmedUsername);
                router.replaceUrl({ url: 'pages/DashboardPage' });
            }
            else {
                this.loginError = (result['message'] as string) ?? '登录失败';
                this.loadCaptcha();
            }
        }
        catch (e) {
            this.loginError = '网络错误，请检查连接';
            this.loadCaptcha();
        }
        finally {
            this.isLoading = false;
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.layoutWeight(1);
            Scroll.scrollable(ScrollDirection.Vertical);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部品牌区
            Column.create();
            // 顶部品牌区
            Column.width('100%');
            // 顶部品牌区
            Column.padding({ top: 40, bottom: 24 });
            // 顶部品牌区
            Column.justifyContent(FlexAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['logo.png'], "bundleName": "xyz.erik.openadmin", "moduleName": "entry" });
            Image.width(64);
            Image.height(64);
            Image.margin({ bottom: 8 });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('开放管理后台');
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#1677FF');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('HarmonyOS 客户端');
            Text.fontSize(12);
            Text.fontColor('#999999');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        // 顶部品牌区
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 表单区
            Column.create();
            // 表单区
            Column.width('100%');
            // 表单区
            Column.padding({ left: 28, right: 28 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 用户名
            TextInput.create({ placeholder: '请输入用户名', text: this.username });
            // 用户名
            TextInput.height(48);
            // 用户名
            TextInput.fontSize(15);
            // 用户名
            TextInput.backgroundColor('#F5F5F5');
            // 用户名
            TextInput.borderRadius(8);
            // 用户名
            TextInput.padding({ left: 16, right: 16 });
            // 用户名
            TextInput.onChange((v: string) => { this.username = v; });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 密码
            Row.create();
            // 密码
            Row.width('100%');
            // 密码
            Row.margin({ top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '请输入密码', text: this.password });
            TextInput.height(48);
            TextInput.fontSize(15);
            TextInput.type(this.showPassword ? InputType.Normal : InputType.Password);
            TextInput.backgroundColor('#F5F5F5');
            TextInput.borderRadius(8);
            TextInput.padding({ left: 16, right: 16 });
            TextInput.layoutWeight(1);
            TextInput.onChange((v: string) => { this.password = v; });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel(this.showPassword ? '隐藏' : '显示');
            Button.fontSize(12);
            Button.fontColor('#1677FF');
            Button.backgroundColor(Color.Transparent);
            Button.width(56);
            Button.onClick(() => { this.showPassword = !this.showPassword; });
        }, Button);
        Button.pop();
        // 密码
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 点击验证码
            if (this.captchaLoading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        LoadingProgress.create();
                        LoadingProgress.width(36);
                        LoadingProgress.height(36);
                        LoadingProgress.color('#1677FF');
                        LoadingProgress.margin({ top: 16 });
                    }, LoadingProgress);
                });
            }
            else if (this.captchaError && !this.captchaData) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.margin({ top: 14 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.captchaError);
                        Text.fontSize(13);
                        Text.fontColor('#FF4D4F');
                        Text.layoutWeight(1);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('重试');
                        Button.fontSize(13);
                        Button.fontColor('#1677FF');
                        Button.backgroundColor(Color.Transparent);
                        Button.onClick(() => { this.loadCaptcha(); });
                    }, Button);
                    Button.pop();
                    Row.pop();
                });
            }
            else if (this.captchaData) {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 提示文字
                        Row.create();
                        // 提示文字
                        Row.width('100%');
                        // 提示文字
                        Row.margin({ top: 14, bottom: 6 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('请按顺序点击图中文字: ');
                        Text.fontSize(12);
                        Text.fontColor('#666666');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, i: number) => {
                            const t = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(i > 0 ? ' → ' : '');
                                Text.fontSize(12);
                                Text.fontColor('#999999');
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`"${t.text}"`);
                                Text.fontSize(13);
                                Text.fontWeight(this.clicks.length === i ? FontWeight.Bold : FontWeight.Normal);
                                Text.fontColor(this.clicks.length > i ? '#52C41A' : (this.clicks.length === i ? '#1677FF' : '#333333'));
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.captchaData!.targets, forEachItemGenFunction, undefined, true, false);
                    }, ForEach);
                    ForEach.pop();
                    // 提示文字
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 验证码图片
                        Stack.create({ alignContent: Alignment.TopStart });
                        // 验证码图片
                        Stack.width('100%');
                        // 验证码图片
                        Stack.height(200);
                        // 验证码图片
                        Stack.margin({ top: 4 });
                    }, Stack);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create((this.captchaData!.image.startsWith('data:') ?? false)
                            ? this.captchaData!.image
                            : `data:image/png;base64,${this.captchaData!.image}`);
                        Image.width('100%');
                        Image.height(200);
                        Image.objectFit(ImageFit.Contain);
                        Image.borderRadius(8);
                        Image.border({ width: 1, color: '#EEEEEE' });
                        Image.onClick((event: ClickEvent) => { this.onCaptchaClick(event); });
                    }, Image);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 点击标记
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const m = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Circle.create({ width: 26, height: 26 });
                                Circle.fill('#1677FFCC');
                                Circle.position({ x: m.x - 13, y: m.y - 13 });
                            }, Circle);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`${m.order}`);
                                Text.fontSize(13);
                                Text.fontColor('#FFFFFF');
                                Text.fontWeight(FontWeight.Bold);
                                Text.position({ x: m.x - 3, y: m.y - 8 });
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.clickMarkers, forEachItemGenFunction);
                    }, ForEach);
                    // 点击标记
                    ForEach.pop();
                    // 验证码图片
                    Stack.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 操作栏
                        Row.create();
                        // 操作栏
                        Row.width('100%');
                        // 操作栏
                        Row.margin({ top: 4 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`已点击 ${this.clicks.length}/${this.captchaData!.targets.length}`);
                        Text.fontSize(12);
                        Text.fontColor('#999999');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('换一张');
                        Button.fontSize(12);
                        Button.fontColor('#1677FF');
                        Button.backgroundColor(Color.Transparent);
                        Button.onClick(() => { this.loadCaptcha(); });
                    }, Button);
                    Button.pop();
                    // 操作栏
                    Row.pop();
                    Column.pop();
                });
            }
            // 错误提示
            else {
                this.ifElseBranchUpdateFunction(3, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 错误提示
            if (this.loginError) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.loginError);
                        Text.fontSize(13);
                        Text.fontColor('#FF4D4F');
                        Text.width('100%');
                        Text.textAlign(TextAlign.Center);
                        Text.padding({ top: 10, bottom: 2 });
                    }, Text);
                    Text.pop();
                });
            }
            // 登录按钮
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 登录按钮
            Button.createWithLabel('登 录');
            // 登录按钮
            Button.width('100%');
            // 登录按钮
            Button.height(48);
            // 登录按钮
            Button.fontSize(16);
            // 登录按钮
            Button.fontColor('#FFFFFF');
            // 登录按钮
            Button.backgroundColor(this.isLoading ? '#99BBFF' : '#1677FF');
            // 登录按钮
            Button.borderRadius(8);
            // 登录按钮
            Button.margin({ top: 20 });
            // 登录按钮
            Button.enabled(!this.isLoading);
            // 登录按钮
            Button.onClick(() => { this.login(); });
        }, Button);
        // 登录按钮
        Button.pop();
        // 表单区
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 底部操作
            Row.create();
            // 底部操作
            Row.justifyContent(FlexAlign.Center);
            // 底部操作
            Row.margin({ top: 16 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('还没有账号？');
            Text.fontSize(13);
            Text.fontColor('#999999');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('立即注册');
            Button.fontSize(13);
            Button.fontColor('#1677FF');
            Button.backgroundColor(Color.Transparent);
            Button.onClick(() => {
                promptAction.showToast({ message: '注册功能即将上线' });
            });
        }, Button);
        Button.pop();
        // 底部操作
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 版权
            Text.create('Copyright (c) 2026 erik — https://erik.xyz');
            // 版权
            Text.fontSize(10);
            // 版权
            Text.fontColor('#CCCCCC');
            // 版权
            Text.textAlign(TextAlign.Center);
            // 版权
            Text.width('100%');
            // 版权
            Text.padding({ top: 20, bottom: 24 });
        }, Text);
        // 版权
        Text.pop();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "LoginPage";
    }
}
registerNamedRoute(() => new LoginPage(undefined, {}), "", { bundleName: "xyz.erik.openadmin", moduleName: "entry", pagePath: "pages/LoginPage", pageFullPath: "entry/src/main/ets/pages/LoginPage", integratedHsp: "false", moduleType: "followWithHap" });
