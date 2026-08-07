if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ProfilePage_Params {
    username?: string;
    role?: string;
    appVersion?: string;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { TokenManager } from "@bundle:xyz.erik.openadmin/entry/ets/utils/TokenManager";
class ProfilePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__username = new ObservedPropertySimplePU('管理员', this, "username");
        this.__role = new ObservedPropertySimplePU('超级管理员', this, "role");
        this.__appVersion = new ObservedPropertySimplePU('1.0.0', this, "appVersion");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ProfilePage_Params) {
        if (params.username !== undefined) {
            this.username = params.username;
        }
        if (params.role !== undefined) {
            this.role = params.role;
        }
        if (params.appVersion !== undefined) {
            this.appVersion = params.appVersion;
        }
    }
    updateStateVars(params: ProfilePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__username.purgeDependencyOnElmtId(rmElmtId);
        this.__role.purgeDependencyOnElmtId(rmElmtId);
        this.__appVersion.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__username.aboutToBeDeleted();
        this.__role.aboutToBeDeleted();
        this.__appVersion.aboutToBeDeleted();
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
    private __role: ObservedPropertySimplePU<string>;
    get role() {
        return this.__role.get();
    }
    set role(newValue: string) {
        this.__role.set(newValue);
    }
    private __appVersion: ObservedPropertySimplePU<string>;
    get appVersion() {
        return this.__appVersion.get();
    }
    set appVersion(newValue: string) {
        this.__appVersion.set(newValue);
    }
    aboutToAppear(): void {
        // 可从 AppStorage 获取登录用户信息
        this.username = (AppStorage.get('adminUsername') as string) ?? '管理员';
    }
    logout(): void {
        AlertDialog.show({
            title: '确认退出',
            message: '确定要退出登录吗？',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            primaryButton: {
                value: '确定退出',
                fontColor: '#FF4D4F',
                action: () => {
                    TokenManager.clearTokens();
                    promptAction.showToast({ message: '已退出登录' });
                    router.replaceUrl({ url: 'pages/LoginPage' });
                }
            },
            secondaryButton: {
                value: '取消',
                action: () => { }
            }
        });
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶栏
            Row.create();
            // 顶栏
            Row.width('100%');
            // 顶栏
            Row.height(56);
            // 顶栏
            Row.padding({ left: 16, right: 16 });
            // 顶栏
            Row.backgroundColor('#FFFFFF');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild({ type: ButtonType.Circle });
            Button.width(36);
            Button.height(36);
            Button.backgroundColor('#FFFFFF');
            Button.onClick(() => router.back());
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['back.png'], "bundleName": "xyz.erik.openadmin", "moduleName": "entry" });
            Image.width(24);
            Image.height(24);
        }, Image);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('个人中心');
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 8 });
        }, Text);
        Text.pop();
        // 顶栏
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.layoutWeight(1);
            Scroll.backgroundColor('#F5F5F5');
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 用户信息卡片
            Column.create();
            // 用户信息卡片
            Column.width('100%');
            // 用户信息卡片
            Column.padding({ top: 32, bottom: 32 });
            // 用户信息卡片
            Column.backgroundColor('#FFFFFF');
            // 用户信息卡片
            Column.margin({ top: 16 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Circle.create({ width: 64, height: 64 });
            Circle.fill('#E6F0FF');
        }, Circle);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.username);
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ top: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.role);
            Text.fontSize(13);
            Text.fontColor('#999999');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        // 用户信息卡片
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 菜单列表
            Column.create();
            // 菜单列表
            Column.width('100%');
            // 菜单列表
            Column.backgroundColor('#FFFFFF');
            // 菜单列表
            Column.borderRadius(8);
            // 菜单列表
            Column.margin({ top: 16, left: 16, right: 16 });
        }, Column);
        this.buildMenuItem.bind(this)('修改密码', '修改登录密码', () => {
            promptAction.showToast({ message: '功能开发中' });
        });
        this.buildMenuItem.bind(this)('清除缓存', '清除本地缓存数据', () => {
            promptAction.showToast({ message: '缓存已清除' });
        });
        this.buildMenuItem.bind(this)('检查更新', `当前版本 ${this.appVersion}`, () => {
            promptAction.showToast({ message: '已是最新版本' });
        });
        this.buildMenuItem.bind(this)('关于', '开放管理后台 HarmonyOS 客户端', () => {
            promptAction.showToast({ message: 'Copyright (c) 2026 erik' });
        });
        // 菜单列表
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 退出按钮
            Button.createWithLabel('退出登录');
            // 退出按钮
            Button.width('100%');
            // 退出按钮
            Button.height(48);
            // 退出按钮
            Button.fontSize(16);
            // 退出按钮
            Button.fontColor('#FF4D4F');
            // 退出按钮
            Button.backgroundColor('#FFFFFF');
            // 退出按钮
            Button.borderRadius(8);
            // 退出按钮
            Button.margin({ top: 32, left: 16, right: 16 });
            // 退出按钮
            Button.onClick(() => {
                this.logout();
            });
        }, Button);
        // 退出按钮
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 版权
            Text.create('Copyright (c) 2026 erik — https://erik.xyz');
            // 版权
            Text.fontSize(11);
            // 版权
            Text.fontColor('#CCCCCC');
            // 版权
            Text.textAlign(TextAlign.Center);
            // 版权
            Text.width('100%');
            // 版权
            Text.margin({ top: 24, bottom: 32 });
        }, Text);
        // 版权
        Text.pop();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    buildMenuItem(title: string, subtitle: string, onClick: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
            Row.onClick(onClick);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.fontSize(15);
            Text.fontColor('#333333');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(subtitle);
            Text.fontSize(12);
            Text.fontColor('#999999');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['arrow_right.png'], "bundleName": "xyz.erik.openadmin", "moduleName": "entry" });
            Image.width(16);
            Image.height(16);
            Image.fillColor('#CCCCCC');
        }, Image);
        Row.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ProfilePage";
    }
}
registerNamedRoute(() => new ProfilePage(undefined, {}), "", { bundleName: "xyz.erik.openadmin", moduleName: "entry", pagePath: "pages/ProfilePage", pageFullPath: "entry/src/main/ets/pages/ProfilePage", integratedHsp: "false", moduleType: "followWithHap" });
