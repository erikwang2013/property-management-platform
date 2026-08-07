if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface UserDetailPage_Params {
    user?: User | null;
    isLoading?: boolean;
    hasError?: boolean;
    isSubmitting?: boolean;
    mode?: string;
    userId?: string;
    formUsername?: string;
    formRealName?: string;
    formPhone?: string;
    formEmail?: string;
    formPassword?: string;
    formStatus?: number;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { UserService } from "@bundle:xyz.erik.openadmin/entry/ets/service/DataService";
import type { User } from '../model/DataModels';
import { LoadingView, ErrorView } from "@bundle:xyz.erik.openadmin/entry/ets/common/Components";
class UserDetailPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__user = new ObservedPropertyObjectPU(null, this, "user");
        this.__isLoading = new ObservedPropertySimplePU(true, this, "isLoading");
        this.__hasError = new ObservedPropertySimplePU(false, this, "hasError");
        this.__isSubmitting = new ObservedPropertySimplePU(false, this, "isSubmitting");
        this.__mode = new ObservedPropertySimplePU('view', this, "mode");
        this.__userId = new ObservedPropertySimplePU('', this, "userId");
        this.__formUsername = new ObservedPropertySimplePU('', this, "formUsername");
        this.__formRealName = new ObservedPropertySimplePU('', this, "formRealName");
        this.__formPhone = new ObservedPropertySimplePU('', this, "formPhone");
        this.__formEmail = new ObservedPropertySimplePU('', this, "formEmail");
        this.__formPassword = new ObservedPropertySimplePU('', this, "formPassword");
        this.__formStatus = new ObservedPropertySimplePU(1, this, "formStatus");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: UserDetailPage_Params) {
        if (params.user !== undefined) {
            this.user = params.user;
        }
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
        if (params.hasError !== undefined) {
            this.hasError = params.hasError;
        }
        if (params.isSubmitting !== undefined) {
            this.isSubmitting = params.isSubmitting;
        }
        if (params.mode !== undefined) {
            this.mode = params.mode;
        }
        if (params.userId !== undefined) {
            this.userId = params.userId;
        }
        if (params.formUsername !== undefined) {
            this.formUsername = params.formUsername;
        }
        if (params.formRealName !== undefined) {
            this.formRealName = params.formRealName;
        }
        if (params.formPhone !== undefined) {
            this.formPhone = params.formPhone;
        }
        if (params.formEmail !== undefined) {
            this.formEmail = params.formEmail;
        }
        if (params.formPassword !== undefined) {
            this.formPassword = params.formPassword;
        }
        if (params.formStatus !== undefined) {
            this.formStatus = params.formStatus;
        }
    }
    updateStateVars(params: UserDetailPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__user.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__hasError.purgeDependencyOnElmtId(rmElmtId);
        this.__isSubmitting.purgeDependencyOnElmtId(rmElmtId);
        this.__mode.purgeDependencyOnElmtId(rmElmtId);
        this.__userId.purgeDependencyOnElmtId(rmElmtId);
        this.__formUsername.purgeDependencyOnElmtId(rmElmtId);
        this.__formRealName.purgeDependencyOnElmtId(rmElmtId);
        this.__formPhone.purgeDependencyOnElmtId(rmElmtId);
        this.__formEmail.purgeDependencyOnElmtId(rmElmtId);
        this.__formPassword.purgeDependencyOnElmtId(rmElmtId);
        this.__formStatus.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__user.aboutToBeDeleted();
        this.__isLoading.aboutToBeDeleted();
        this.__hasError.aboutToBeDeleted();
        this.__isSubmitting.aboutToBeDeleted();
        this.__mode.aboutToBeDeleted();
        this.__userId.aboutToBeDeleted();
        this.__formUsername.aboutToBeDeleted();
        this.__formRealName.aboutToBeDeleted();
        this.__formPhone.aboutToBeDeleted();
        this.__formEmail.aboutToBeDeleted();
        this.__formPassword.aboutToBeDeleted();
        this.__formStatus.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __user: ObservedPropertyObjectPU<User | null>;
    get user() {
        return this.__user.get();
    }
    set user(newValue: User | null) {
        this.__user.set(newValue);
    }
    private __isLoading: ObservedPropertySimplePU<boolean>;
    get isLoading() {
        return this.__isLoading.get();
    }
    set isLoading(newValue: boolean) {
        this.__isLoading.set(newValue);
    }
    private __hasError: ObservedPropertySimplePU<boolean>;
    get hasError() {
        return this.__hasError.get();
    }
    set hasError(newValue: boolean) {
        this.__hasError.set(newValue);
    }
    private __isSubmitting: ObservedPropertySimplePU<boolean>;
    get isSubmitting() {
        return this.__isSubmitting.get();
    }
    set isSubmitting(newValue: boolean) {
        this.__isSubmitting.set(newValue);
    }
    private __mode: ObservedPropertySimplePU<string>;
    get mode() {
        return this.__mode.get();
    }
    set mode(newValue: string) {
        this.__mode.set(newValue);
    }
    private __userId: ObservedPropertySimplePU<string>;
    get userId() {
        return this.__userId.get();
    }
    set userId(newValue: string) {
        this.__userId.set(newValue);
    }
    // 表单状态
    private __formUsername: ObservedPropertySimplePU<string>;
    get formUsername() {
        return this.__formUsername.get();
    }
    set formUsername(newValue: string) {
        this.__formUsername.set(newValue);
    }
    private __formRealName: ObservedPropertySimplePU<string>;
    get formRealName() {
        return this.__formRealName.get();
    }
    set formRealName(newValue: string) {
        this.__formRealName.set(newValue);
    }
    private __formPhone: ObservedPropertySimplePU<string>;
    get formPhone() {
        return this.__formPhone.get();
    }
    set formPhone(newValue: string) {
        this.__formPhone.set(newValue);
    }
    private __formEmail: ObservedPropertySimplePU<string>;
    get formEmail() {
        return this.__formEmail.get();
    }
    set formEmail(newValue: string) {
        this.__formEmail.set(newValue);
    }
    private __formPassword: ObservedPropertySimplePU<string>;
    get formPassword() {
        return this.__formPassword.get();
    }
    set formPassword(newValue: string) {
        this.__formPassword.set(newValue);
    }
    private __formStatus: ObservedPropertySimplePU<number>;
    get formStatus() {
        return this.__formStatus.get();
    }
    set formStatus(newValue: number) {
        this.__formStatus.set(newValue);
    }
    aboutToAppear(): void {
        const params = (router.getParams() ?? {}) as Record<string, Object>;
        this.mode = (params?.['mode'] as string) ?? 'view';
        this.userId = (params?.['userId'] as string) ?? '';
        if (this.mode !== 'create') {
            this.loadDetail();
        }
        else {
            this.isLoading = false;
        }
    }
    async loadDetail(): Promise<void> {
        this.isLoading = true;
        try {
            this.user = await UserService.getDetail(this.userId);
            this.formUsername = this.user.username;
            this.formRealName = this.user.real_name;
            this.formPhone = this.user.phone ?? '';
            this.formEmail = this.user.email ?? '';
            this.formStatus = this.user.status;
        }
        catch (e) {
            if (e instanceof Error && e.message === 'UNAUTHORIZED') {
                router.replaceUrl({ url: 'pages/LoginPage' });
                return;
            }
            this.hasError = true;
        }
        finally {
            this.isLoading = false;
        }
    }
    async save(): Promise<void> {
        if (!this.formUsername.trim()) {
            promptAction.showToast({ message: '请输入用户名' });
            return;
        }
        if (this.mode === 'create' && !this.formPassword) {
            promptAction.showToast({ message: '请输入密码' });
            return;
        }
        this.isSubmitting = true;
        try {
            if (this.mode === 'create') {
                await UserService.create({
                    username: this.formUsername,
                    real_name: this.formRealName,
                    password: this.formPassword,
                    phone: this.formPhone,
                    email: this.formEmail,
                    status: this.formStatus
                });
                promptAction.showToast({ message: '创建成功' });
            }
            else {
                await UserService.update(this.userId, {
                    real_name: this.formRealName,
                    phone: this.formPhone,
                    email: this.formEmail,
                    status: this.formStatus
                });
                promptAction.showToast({ message: '更新成功' });
            }
            router.back();
        }
        catch (e) {
            if (e instanceof Error && e.message === 'UNAUTHORIZED') {
                router.replaceUrl({ url: 'pages/LoginPage' });
                return;
            }
            promptAction.showToast({ message: '保存失败' });
        }
        finally {
            this.isSubmitting = false;
        }
    }
    async deleteUser(): Promise<void> {
        AlertDialog.show({
            title: '确认删除',
            message: '确定要删除该用户吗？删除后不可恢复。',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            primaryButton: {
                value: '确定',
                fontColor: '#FF4D4F',
                action: async () => {
                    try {
                        await UserService.delete(this.userId);
                        promptAction.showToast({ message: '删除成功' });
                        router.back();
                    }
                    catch (e) {
                        if (e instanceof Error && e.message === 'UNAUTHORIZED') {
                            router.replaceUrl({ url: 'pages/LoginPage' });
                            return;
                        }
                        promptAction.showToast({ message: '删除失败' });
                    }
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
            Text.create(this.mode === 'create' ? '新增用户' : '用户详情');
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.mode !== 'create') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('删除');
                        Button.fontSize(13);
                        Button.fontColor('#FF4D4F');
                        Button.backgroundColor('#FFE6E6');
                        Button.borderRadius(4);
                        Button.height(32);
                        Button.onClick(() => this.deleteUser());
                    }, Button);
                    Button.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 顶栏
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.isLoading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new LoadingView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/UserDetailPage.ets", line: 168, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {};
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {});
                            }
                        }, { name: "LoadingView" });
                    }
                });
            }
            else if (this.hasError) {
                this.ifElseBranchUpdateFunction(1, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new ErrorView(this, { onRetry: () => this.loadDetail() }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/UserDetailPage.ets", line: 170, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        onRetry: () => this.loadDetail()
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {});
                            }
                        }, { name: "ErrorView" });
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
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
                        // 头像
                        Circle.create({ width: 72, height: 72 });
                        // 头像
                        Circle.fill('#E6F0FF');
                        // 头像
                        Circle.margin({ top: 24, bottom: 24 });
                    }, Circle);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                        Row.create();
                        // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                        Row.width('100%');
                        // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                        Row.height(56);
                        // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                        Row.padding({ left: 16, right: 16 });
                        // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                        Row.backgroundColor('#FFFFFF');
                        // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                        Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                        // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('用户名');
                        Text.fontSize(15);
                        Text.fontColor('#333333');
                        Text.width(80);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '请输入用户名', text: this.formUsername });
                        TextInput.fontSize(15);
                        TextInput.layoutWeight(1);
                        TextInput.enabled(this.mode === 'create');
                        TextInput.onChange((v: string) => { this.formUsername = v; });
                    }, TextInput);
                    // 表单（行内直接内联，避免在 @Builder 中调用函数参数）
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.mode === 'create') {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Row.create();
                                    Row.width('100%');
                                    Row.height(56);
                                    Row.padding({ left: 16, right: 16 });
                                    Row.backgroundColor('#FFFFFF');
                                    Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                                    Row.alignItems(VerticalAlign.Center);
                                }, Row);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('密码');
                                    Text.fontSize(15);
                                    Text.fontColor('#333333');
                                    Text.width(80);
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    TextInput.create({ placeholder: '请输入密码', text: this.formPassword });
                                    TextInput.fontSize(15);
                                    TextInput.layoutWeight(1);
                                    TextInput.type(InputType.Password);
                                    TextInput.onChange((v: string) => { this.formPassword = v; });
                                }, TextInput);
                                Row.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.height(56);
                        Row.padding({ left: 16, right: 16 });
                        Row.backgroundColor('#FFFFFF');
                        Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('姓名');
                        Text.fontSize(15);
                        Text.fontColor('#333333');
                        Text.width(80);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '请输入真实姓名', text: this.formRealName });
                        TextInput.fontSize(15);
                        TextInput.layoutWeight(1);
                        TextInput.onChange((v: string) => { this.formRealName = v; });
                    }, TextInput);
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.height(56);
                        Row.padding({ left: 16, right: 16 });
                        Row.backgroundColor('#FFFFFF');
                        Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('手机号');
                        Text.fontSize(15);
                        Text.fontColor('#333333');
                        Text.width(80);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '请输入手机号', text: this.formPhone });
                        TextInput.fontSize(15);
                        TextInput.layoutWeight(1);
                        TextInput.type(InputType.PhoneNumber);
                        TextInput.onChange((v: string) => { this.formPhone = v; });
                    }, TextInput);
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.height(56);
                        Row.padding({ left: 16, right: 16 });
                        Row.backgroundColor('#FFFFFF');
                        Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('邮箱');
                        Text.fontSize(15);
                        Text.fontColor('#333333');
                        Text.width(80);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '请输入邮箱', text: this.formEmail });
                        TextInput.fontSize(15);
                        TextInput.layoutWeight(1);
                        TextInput.type(InputType.Email);
                        TextInput.onChange((v: string) => { this.formEmail = v; });
                    }, TextInput);
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 状态行（直接内联，避免在回调中书写组件块）
                        Row.create();
                        // 状态行（直接内联，避免在回调中书写组件块）
                        Row.width('100%');
                        // 状态行（直接内联，避免在回调中书写组件块）
                        Row.height(56);
                        // 状态行（直接内联，避免在回调中书写组件块）
                        Row.padding({ left: 16, right: 16 });
                        // 状态行（直接内联，避免在回调中书写组件块）
                        Row.backgroundColor('#FFFFFF');
                        // 状态行（直接内联，避免在回调中书写组件块）
                        Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                        // 状态行（直接内联，避免在回调中书写组件块）
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('状态');
                        Text.fontSize(15);
                        Text.fontColor('#333333');
                        Text.width(80);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.layoutWeight(1);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('启用');
                        Button.fontSize(13);
                        Button.fontColor(this.formStatus === 1 ? '#FFFFFF' : '#666666');
                        Button.backgroundColor(this.formStatus === 1 ? '#52C41A' : '#F5F5F5');
                        Button.borderRadius(4);
                        Button.height(32);
                        Button.onClick(() => { this.formStatus = 1; });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('禁用');
                        Button.fontSize(13);
                        Button.fontColor(this.formStatus === 0 ? '#FFFFFF' : '#666666');
                        Button.backgroundColor(this.formStatus === 0 ? '#FF4D4F' : '#F5F5F5');
                        Button.borderRadius(4);
                        Button.height(32);
                        Button.margin({ left: 12 });
                        Button.onClick(() => { this.formStatus = 0; });
                    }, Button);
                    Button.pop();
                    Row.pop();
                    // 状态行（直接内联，避免在回调中书写组件块）
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 提交按钮
                        Button.createWithLabel('保 存');
                        // 提交按钮
                        Button.width('100%');
                        // 提交按钮
                        Button.height(48);
                        // 提交按钮
                        Button.fontSize(16);
                        // 提交按钮
                        Button.fontColor('#FFFFFF');
                        // 提交按钮
                        Button.backgroundColor(this.isSubmitting ? '#99BBFF' : '#1677FF');
                        // 提交按钮
                        Button.borderRadius(8);
                        // 提交按钮
                        Button.margin({ top: 32, left: 16, right: 16, bottom: 32 });
                        // 提交按钮
                        Button.enabled(!this.isSubmitting);
                        // 提交按钮
                        Button.onClick(() => { this.save(); });
                    }, Button);
                    // 提交按钮
                    Button.pop();
                    Column.pop();
                    Scroll.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "UserDetailPage";
    }
}
registerNamedRoute(() => new UserDetailPage(undefined, {}), "", { bundleName: "xyz.erik.openadmin", moduleName: "entry", pagePath: "pages/UserDetailPage", pageFullPath: "entry/src/main/ets/pages/UserDetailPage", integratedHsp: "false", moduleType: "followWithHap" });
