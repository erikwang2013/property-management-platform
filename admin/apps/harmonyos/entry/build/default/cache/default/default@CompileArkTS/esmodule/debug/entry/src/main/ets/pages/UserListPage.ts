if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface UserListPage_Params {
    users?: User[];
    page?: number;
    total?: number;
    isLoading?: boolean;
    hasError?: boolean;
    keyword?: string;
    isRefreshing?: boolean;
    limit?: number;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { UserService } from "@bundle:xyz.erik.openadmin/entry/ets/service/DataService";
import type { User } from '../model/DataModels';
import { LoadingView, ErrorView, EmptyView } from "@bundle:xyz.erik.openadmin/entry/ets/common/Components";
class UserListPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__users = new ObservedPropertyObjectPU([], this, "users");
        this.__page = new ObservedPropertySimplePU(1, this, "page");
        this.__total = new ObservedPropertySimplePU(0, this, "total");
        this.__isLoading = new ObservedPropertySimplePU(true, this, "isLoading");
        this.__hasError = new ObservedPropertySimplePU(false, this, "hasError");
        this.__keyword = new ObservedPropertySimplePU('', this, "keyword");
        this.__isRefreshing = new ObservedPropertySimplePU(false, this, "isRefreshing");
        this.limit = 15;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: UserListPage_Params) {
        if (params.users !== undefined) {
            this.users = params.users;
        }
        if (params.page !== undefined) {
            this.page = params.page;
        }
        if (params.total !== undefined) {
            this.total = params.total;
        }
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
        if (params.hasError !== undefined) {
            this.hasError = params.hasError;
        }
        if (params.keyword !== undefined) {
            this.keyword = params.keyword;
        }
        if (params.isRefreshing !== undefined) {
            this.isRefreshing = params.isRefreshing;
        }
        if (params.limit !== undefined) {
            this.limit = params.limit;
        }
    }
    updateStateVars(params: UserListPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__users.purgeDependencyOnElmtId(rmElmtId);
        this.__page.purgeDependencyOnElmtId(rmElmtId);
        this.__total.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__hasError.purgeDependencyOnElmtId(rmElmtId);
        this.__keyword.purgeDependencyOnElmtId(rmElmtId);
        this.__isRefreshing.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__users.aboutToBeDeleted();
        this.__page.aboutToBeDeleted();
        this.__total.aboutToBeDeleted();
        this.__isLoading.aboutToBeDeleted();
        this.__hasError.aboutToBeDeleted();
        this.__keyword.aboutToBeDeleted();
        this.__isRefreshing.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __users: ObservedPropertyObjectPU<User[]>;
    get users() {
        return this.__users.get();
    }
    set users(newValue: User[]) {
        this.__users.set(newValue);
    }
    private __page: ObservedPropertySimplePU<number>;
    get page() {
        return this.__page.get();
    }
    set page(newValue: number) {
        this.__page.set(newValue);
    }
    private __total: ObservedPropertySimplePU<number>;
    get total() {
        return this.__total.get();
    }
    set total(newValue: number) {
        this.__total.set(newValue);
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
    private __keyword: ObservedPropertySimplePU<string>;
    get keyword() {
        return this.__keyword.get();
    }
    set keyword(newValue: string) {
        this.__keyword.set(newValue);
    }
    private __isRefreshing: ObservedPropertySimplePU<boolean>;
    get isRefreshing() {
        return this.__isRefreshing.get();
    }
    set isRefreshing(newValue: boolean) {
        this.__isRefreshing.set(newValue);
    }
    private readonly limit: number;
    aboutToAppear(): void {
        this.loadData();
    }
    async loadData(isRefresh: boolean = false): Promise<void> {
        if (isRefresh) {
            this.page = 1;
            this.isRefreshing = true;
        }
        else {
            this.isLoading = true;
        }
        this.hasError = false;
        try {
            const result = await UserService.getList({
                page: this.page,
                limit: this.limit,
                keyword: this.keyword || undefined
            });
            if (isRefresh || this.page === 1) {
                this.users = result.list;
            }
            else {
                this.users = this.users.concat(result.list);
            }
            this.total = result.total;
        }
        catch (e) {
            if (e instanceof Error && e.message === 'UNAUTHORIZED') {
                router.replaceUrl({ url: 'pages/LoginPage' });
                return;
            }
            this.hasError = true;
            promptAction.showToast({ message: '加载失败' });
        }
        finally {
            this.isLoading = false;
            this.isRefreshing = false;
        }
    }
    loadMore(): void {
        if (this.users.length >= this.total)
            return;
        this.page++;
        this.loadData();
    }
    onSearch(): void {
        this.page = 1;
        this.loadData(true);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#F5F5F5');
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
            Text.create('用户管理');
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
            Button.createWithLabel('+ 新增');
            Button.fontSize(13);
            Button.fontColor('#FFFFFF');
            Button.backgroundColor('#1677FF');
            Button.borderRadius(4);
            Button.height(32);
            Button.onClick(() => {
                router.pushUrl({ url: 'pages/UserDetailPage', params: { mode: 'create' } });
            });
        }, Button);
        Button.pop();
        // 顶栏
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 搜索栏
            Row.create();
            // 搜索栏
            Row.width('100%');
            // 搜索栏
            Row.padding({ left: 16, right: 16, top: 8, bottom: 8 });
            // 搜索栏
            Row.backgroundColor('#FFFFFF');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '搜索用户名或姓名', text: this.keyword });
            TextInput.height(40);
            TextInput.fontSize(14);
            TextInput.backgroundColor('#F5F5F5');
            TextInput.borderRadius(8);
            TextInput.layoutWeight(1);
            TextInput.padding({ left: 12, right: 12 });
            TextInput.onChange((value: string) => {
                this.keyword = value;
            });
            TextInput.onSubmit(() => {
                this.onSearch();
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('搜索');
            Button.fontSize(13);
            Button.fontColor('#FFFFFF');
            Button.backgroundColor('#1677FF');
            Button.borderRadius(4);
            Button.width(60);
            Button.height(40);
            Button.margin({ left: 8 });
            Button.onClick(() => {
                this.onSearch();
            });
        }, Button);
        Button.pop();
        // 搜索栏
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 内容
            if (this.isLoading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new LoadingView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/UserListPage.ets", line: 139, col: 9 });
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
                                let componentCall = new ErrorView(this, { onRetry: () => this.loadData(true) }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/UserListPage.ets", line: 141, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        onRetry: () => this.loadData(true)
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
            else if (this.users.length === 0) {
                this.ifElseBranchUpdateFunction(2, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new EmptyView(this, { message: '暂无用户数据' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/UserListPage.ets", line: 143, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        message: '暂无用户数据'
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    message: '暂无用户数据'
                                });
                            }
                        }, { name: "EmptyView" });
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(3, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 刷新组件
                        Refresh.create({ refreshing: { value: this.isRefreshing, changeEvent: newValue => { this.isRefreshing = newValue; } } });
                        // 刷新组件
                        Refresh.onRefreshing(() => {
                            this.loadData(true);
                        });
                    }, Refresh);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create();
                        List.onReachEnd(() => {
                            // 通过 ListItem 中的按钮手动加载更多
                        });
                        List.width('100%');
                        List.layoutWeight(1);
                        List.edgeEffect(EdgeEffect.Spring);
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, index: number) => {
                            const user = _item;
                            {
                                const itemCreation = (elmtId, isInitialRender) => {
                                    ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                                    ListItem.create(deepRenderFunction, true);
                                    if (!isInitialRender) {
                                        ListItem.pop();
                                    }
                                    ViewStackProcessor.StopGetAccessRecording();
                                };
                                const itemCreation2 = (elmtId, isInitialRender) => {
                                    ListItem.create(deepRenderFunction, true);
                                };
                                const deepRenderFunction = (elmtId, isInitialRender) => {
                                    itemCreation(elmtId, isInitialRender);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Row.create();
                                        Row.width('100%');
                                        Row.height(64);
                                        Row.padding({ left: 16, right: 16 });
                                        Row.backgroundColor('#FFFFFF');
                                        Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                                        Row.onClick(() => {
                                            router.pushUrl({
                                                url: 'pages/UserDetailPage',
                                                params: { mode: 'edit', userId: user.id }
                                            });
                                        });
                                    }, Row);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        // 头像
                                        Circle.create({ width: 40, height: 40 });
                                        // 头像
                                        Circle.fill('#E6F0FF');
                                    }, Circle);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        // 信息
                                        Column.create();
                                        // 信息
                                        Column.alignItems(HorizontalAlign.Start);
                                        // 信息
                                        Column.layoutWeight(1);
                                        // 信息
                                        Column.margin({ left: 12 });
                                    }, Column);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Row.create();
                                    }, Row);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(user.username);
                                        Text.fontSize(15);
                                        Text.fontWeight(FontWeight.Medium);
                                    }, Text);
                                    Text.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(user.status === 1 ? '启用' : '禁用');
                                        Text.fontSize(10);
                                        Text.fontColor(user.status === 1 ? '#52C41A' : '#FF4D4F');
                                        Text.backgroundColor(user.status === 1 ? '#E6FFF0' : '#FFE6E6');
                                        Text.borderRadius(2);
                                        Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                                        Text.margin({ left: 8 });
                                    }, Text);
                                    Text.pop();
                                    Row.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(user.real_name);
                                        Text.fontSize(12);
                                        Text.fontColor('#999999');
                                        Text.margin({ top: 2 });
                                    }, Text);
                                    Text.pop();
                                    // 信息
                                    Column.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Image.create({ "id": 0, "type": 30000, params: ['arrow_right.png'], "bundleName": "xyz.erik.openadmin", "moduleName": "entry" });
                                        Image.width(16);
                                        Image.height(16);
                                        Image.fillColor('#CCCCCC');
                                    }, Image);
                                    Row.pop();
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.users, forEachItemGenFunction, undefined, true, false);
                    }, ForEach);
                    ForEach.pop();
                    {
                        const itemCreation = (elmtId, isInitialRender) => {
                            ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                            ListItem.create(deepRenderFunction, true);
                            if (!isInitialRender) {
                                // 加载更多
                                ListItem.pop();
                            }
                            ViewStackProcessor.StopGetAccessRecording();
                        };
                        const itemCreation2 = (elmtId, isInitialRender) => {
                            ListItem.create(deepRenderFunction, true);
                        };
                        const deepRenderFunction = (elmtId, isInitialRender) => {
                            itemCreation(elmtId, isInitialRender);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.justifyContent(FlexAlign.Center);
                                Row.width('100%');
                                Row.height(48);
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                If.create();
                                if (this.users.length >= this.total) {
                                    this.ifElseBranchUpdateFunction(0, () => {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create('— 没有更多了 —');
                                            Text.fontSize(12);
                                            Text.fontColor('#CCCCCC');
                                        }, Text);
                                        Text.pop();
                                    });
                                }
                                else {
                                    this.ifElseBranchUpdateFunction(1, () => {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Button.createWithLabel('加载更多');
                                            Button.fontSize(13);
                                            Button.fontColor('#1677FF');
                                            Button.backgroundColor(Color.Transparent);
                                            Button.onClick(() => this.loadMore());
                                        }, Button);
                                        Button.pop();
                                    });
                                }
                            }, If);
                            If.pop();
                            Row.pop();
                            // 加载更多
                            ListItem.pop();
                        };
                        this.observeComponentCreation2(itemCreation2, ListItem);
                        // 加载更多
                        ListItem.pop();
                    }
                    List.pop();
                    // 刷新组件
                    Refresh.pop();
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
        return "UserListPage";
    }
}
registerNamedRoute(() => new UserListPage(undefined, {}), "", { bundleName: "xyz.erik.openadmin", moduleName: "entry", pagePath: "pages/UserListPage", pageFullPath: "entry/src/main/ets/pages/UserListPage", integratedHsp: "false", moduleType: "followWithHap" });
