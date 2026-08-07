if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ProfilePage_Params {
    username?: string;
    phone?: string;
    oldPassword?: string;
    newPassword?: string;
    api?: ApiService;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { ApiService } from "@bundle:com.erik.property.owner/entry/ets/services/ApiService";
import type { PasswordRequest } from '../model/Models';
class ProfilePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__username = new ObservedPropertySimplePU('', this, "username");
        this.__phone = new ObservedPropertySimplePU('', this, "phone");
        this.__oldPassword = new ObservedPropertySimplePU('', this, "oldPassword");
        this.__newPassword = new ObservedPropertySimplePU('', this, "newPassword");
        this.api = ApiService.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ProfilePage_Params) {
        if (params.username !== undefined) {
            this.username = params.username;
        }
        if (params.phone !== undefined) {
            this.phone = params.phone;
        }
        if (params.oldPassword !== undefined) {
            this.oldPassword = params.oldPassword;
        }
        if (params.newPassword !== undefined) {
            this.newPassword = params.newPassword;
        }
        if (params.api !== undefined) {
            this.api = params.api;
        }
    }
    updateStateVars(params: ProfilePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__username.purgeDependencyOnElmtId(rmElmtId);
        this.__phone.purgeDependencyOnElmtId(rmElmtId);
        this.__oldPassword.purgeDependencyOnElmtId(rmElmtId);
        this.__newPassword.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__username.aboutToBeDeleted();
        this.__phone.aboutToBeDeleted();
        this.__oldPassword.aboutToBeDeleted();
        this.__newPassword.aboutToBeDeleted();
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
    private __phone: ObservedPropertySimplePU<string>;
    get phone() {
        return this.__phone.get();
    }
    set phone(newValue: string) {
        this.__phone.set(newValue);
    }
    private __oldPassword: ObservedPropertySimplePU<string>;
    get oldPassword() {
        return this.__oldPassword.get();
    }
    set oldPassword(newValue: string) {
        this.__oldPassword.set(newValue);
    }
    private __newPassword: ObservedPropertySimplePU<string>;
    get newPassword() {
        return this.__newPassword.get();
    }
    set newPassword(newValue: string) {
        this.__newPassword.set(newValue);
    }
    private api: ApiService;
    async aboutToAppear(): Promise<void> {
        await this.api.init();
        this.loadProfile();
    }
    async loadProfile(): Promise<void> {
        try {
            const resp = await this.api.get('/service/profile') as Record<string, Object>;
            if (resp['code'] === 0) {
                const data = resp['data'] as Record<string, string>;
                this.username = data['username'] || data['name'] || '';
                this.phone = data['phone'] || '';
            }
        }
        catch (e) { }
    }
    async changePassword(): Promise<void> {
        if (!this.oldPassword || !this.newPassword) {
            promptAction.showToast({ message: '请输入旧密码和新密码' });
            return;
        }
        try {
            const params: PasswordRequest = { old_password: this.oldPassword, new_password: this.newPassword };
            const resp = await this.api.put('/service/profile/password', params) as Record<string, Object>;
            if (resp['code'] === 0) {
                promptAction.showToast({ message: '密码修改成功' });
                this.oldPassword = '';
                this.newPassword = '';
            }
            else {
                promptAction.showToast({ message: resp['message'] as string || '修改失败' });
            }
        }
        catch (e) {
            promptAction.showToast({ message: '修改失败，请重试' });
        }
    }
    async logout(): Promise<void> {
        try {
            await this.api.post('/service/profile/logout');
        }
        catch (e) { }
        router.replaceUrl({ url: 'pages/LoginPage' });
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#F5F5F5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding(16);
            Row.backgroundColor('#FFF');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('个人中心');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(20);
            Column.backgroundColor('#FFF');
            Column.margin({ top: 8 });
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.username || '用户');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.phone || '');
            Text.fontSize(14);
            Text.fontColor('#999');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFF');
            Column.margin({ top: 8 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('修改密码');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '旧密码', text: this.oldPassword });
            TextInput.type(InputType.Password);
            TextInput.width('100%');
            TextInput.margin({ bottom: 8 });
            TextInput.onChange((v: string) => { this.oldPassword = v; });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '新密码', text: this.newPassword });
            TextInput.type(InputType.Password);
            TextInput.width('100%');
            TextInput.margin({ bottom: 12 });
            TextInput.onChange((v: string) => { this.newPassword = v; });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('保存修改');
            Button.width('100%');
            Button.backgroundColor('#007AFF');
            Button.borderRadius(8);
            Button.onClick(() => { this.changePassword(); });
        }, Button);
        Button.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('退出登录');
            Button.width('90%');
            Button.margin({ top: 32 });
            Button.backgroundColor('#FF4444');
            Button.borderRadius(8);
            Button.onClick(() => { this.logout(); });
        }, Button);
        Button.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ProfilePage";
    }
}
registerNamedRoute(() => new ProfilePage(undefined, {}), "", { bundleName: "com.erik.property.owner", moduleName: "entry", pagePath: "pages/ProfilePage", pageFullPath: "entry/src/main/ets/pages/ProfilePage", integratedHsp: "false", moduleType: "followWithHap" });
