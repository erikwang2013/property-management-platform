if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface LoginPage_Params {
    phone?: string;
    password?: string;
    loading?: boolean;
    auth?: AuthService;
}
import router from "@ohos:router";
import { AuthService } from "@bundle:com.erik.property.owner/entry/ets/services/AuthService";
class LoginPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__phone = new ObservedPropertySimplePU('', this, "phone");
        this.__password = new ObservedPropertySimplePU('', this, "password");
        this.__loading = new ObservedPropertySimplePU(false, this, "loading");
        this.auth = new AuthService();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: LoginPage_Params) {
        if (params.phone !== undefined) {
            this.phone = params.phone;
        }
        if (params.password !== undefined) {
            this.password = params.password;
        }
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.auth !== undefined) {
            this.auth = params.auth;
        }
    }
    updateStateVars(params: LoginPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__phone.purgeDependencyOnElmtId(rmElmtId);
        this.__password.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__phone.aboutToBeDeleted();
        this.__password.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __phone: ObservedPropertySimplePU<string>;
    get phone() {
        return this.__phone.get();
    }
    set phone(newValue: string) {
        this.__phone.set(newValue);
    }
    private __password: ObservedPropertySimplePU<string>;
    get password() {
        return this.__password.get();
    }
    set password(newValue: string) {
        this.__password.set(newValue);
    }
    private __loading: ObservedPropertySimplePU<boolean>;
    get loading() {
        return this.__loading.get();
    }
    set loading(newValue: boolean) {
        this.__loading.set(newValue);
    }
    private auth: AuthService;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.justifyContent(FlexAlign.Center);
            Column.padding(32);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('物业管理平台');
            Text.fontSize(24);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('业主登录');
            Text.fontSize(14);
            Text.fontColor('#999');
            Text.margin({ bottom: 32 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '请输入手机号', text: this.phone });
            TextInput.type(InputType.PhoneNumber);
            TextInput.maxLength(11);
            TextInput.onChange((value: string) => { this.phone = value; });
            TextInput.margin({ bottom: 16 });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '请输入密码', text: this.password });
            TextInput.type(InputType.Password);
            TextInput.onChange((value: string) => { this.password = value; });
            TextInput.margin({ bottom: 24 });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('登 录');
            Button.width('100%');
            Button.height(44);
            Button.enabled(!this.loading);
            Button.onClick(async () => {
                this.loading = true;
                try {
                    await this.auth.login(this.phone, this.password, '', []);
                    router.replaceUrl({ url: 'pages/HomePage' });
                }
                catch (e) {
                    AlertDialog.show({ message: '登录失败: ' + JSON.stringify(e) });
                }
                this.loading = false;
            });
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('还没有账号？立即注册');
            Button.type(ButtonType.Normal);
            Button.backgroundColor(Color.Transparent);
            Button.margin({ top: 12 });
        }, Button);
        Button.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "LoginPage";
    }
}
registerNamedRoute(() => new LoginPage(undefined, {}), "", { bundleName: "com.erik.property.owner", moduleName: "entry", pagePath: "pages/LoginPage", pageFullPath: "entry/src/main/ets/pages/LoginPage", integratedHsp: "false", moduleType: "followWithHap" });
