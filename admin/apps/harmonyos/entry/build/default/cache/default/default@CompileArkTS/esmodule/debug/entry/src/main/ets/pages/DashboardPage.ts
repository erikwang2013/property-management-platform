if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface DashboardPage_Params {
    dashboardData?: DashboardData | null;
    isLoading?: boolean;
    hasError?: boolean;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { DashboardService } from "@bundle:xyz.erik.openadmin/entry/ets/service/DataService";
import type { DashboardData, StatCard as StatCardType, OperationLogItem } from '../model/DataModels';
import { StatCard, LoadingView, ErrorView, EmptyView, CopyrightBar } from "@bundle:xyz.erik.openadmin/entry/ets/common/Components";
class DashboardPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__dashboardData = new ObservedPropertyObjectPU(null, this, "dashboardData");
        this.__isLoading = new ObservedPropertySimplePU(true, this, "isLoading");
        this.__hasError = new ObservedPropertySimplePU(false, this, "hasError");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: DashboardPage_Params) {
        if (params.dashboardData !== undefined) {
            this.dashboardData = params.dashboardData;
        }
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
        if (params.hasError !== undefined) {
            this.hasError = params.hasError;
        }
    }
    updateStateVars(params: DashboardPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__dashboardData.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__hasError.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__dashboardData.aboutToBeDeleted();
        this.__isLoading.aboutToBeDeleted();
        this.__hasError.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __dashboardData: ObservedPropertyObjectPU<DashboardData | null>;
    get dashboardData() {
        return this.__dashboardData.get();
    }
    set dashboardData(newValue: DashboardData | null) {
        this.__dashboardData.set(newValue);
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
    aboutToAppear(): void {
        this.loadDashboard();
    }
    async loadDashboard(): Promise<void> {
        this.isLoading = true;
        this.hasError = false;
        try {
            this.dashboardData = await DashboardService.getDashboard();
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
            Text.create('仪表盘');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 导出菜单
            Button.createWithLabel('导出');
            // 导出菜单
            Button.fontSize(13);
            // 导出菜单
            Button.fontColor('#1677FF');
            // 导出菜单
            Button.backgroundColor('#E6F0FF');
            // 导出菜单
            Button.borderRadius(4);
            // 导出菜单
            Button.onClick(() => {
                promptAction.showToast({ message: '导出功能已触发，查看系统通知' });
            });
        }, Button);
        // 导出菜单
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['avatar.png'], "bundleName": "xyz.erik.openadmin", "moduleName": "entry" });
            Image.width(36);
            Image.height(36);
            Image.borderRadius(18);
            Image.margin({ left: 12 });
            Image.onClick(() => {
                router.pushUrl({ url: 'pages/ProfilePage' });
            });
        }, Image);
        // 顶栏
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 内容区
            if (this.isLoading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new LoadingView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/DashboardPage.ets", line: 74, col: 9 });
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
                                let componentCall = new ErrorView(this, { onRetry: () => this.loadDashboard() }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/DashboardPage.ets", line: 76, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        onRetry: () => this.loadDashboard()
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
            else if (!this.dashboardData) {
                this.ifElseBranchUpdateFunction(2, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new EmptyView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/DashboardPage.ets", line: 78, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {};
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {});
                            }
                        }, { name: "EmptyView" });
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(3, () => {
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
                        // 统计卡片网格
                        Grid.create();
                        // 统计卡片网格
                        Grid.columnsTemplate('1fr 1fr');
                        // 统计卡片网格
                        Grid.rowsGap(12);
                        // 统计卡片网格
                        Grid.columnsGap(12);
                        // 统计卡片网格
                        Grid.width('100%');
                        // 统计卡片网格
                        Grid.margin({ top: 16 });
                        // 统计卡片网格
                        Grid.padding({ left: 16, right: 16 });
                    }, Grid);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, index: number) => {
                            const stat = _item;
                            {
                                const itemCreation2 = (elmtId, isInitialRender) => {
                                    GridItem.create(() => { }, false);
                                };
                                const observedDeepRender = () => {
                                    this.observeComponentCreation2(itemCreation2, GridItem);
                                    {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            if (isInitialRender) {
                                                let componentCall = new StatCard(this, {
                                                    label: stat.label,
                                                    value: stat.value,
                                                    icon: stat.icon,
                                                    color: stat.color,
                                                    trend: stat.trend
                                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/DashboardPage.ets", line: 86, col: 19 });
                                                ViewPU.create(componentCall);
                                                let paramsLambda = () => {
                                                    return {
                                                        label: stat.label,
                                                        value: stat.value,
                                                        icon: stat.icon,
                                                        color: stat.color,
                                                        trend: stat.trend
                                                    };
                                                };
                                                componentCall.paramsGenerator_ = paramsLambda;
                                            }
                                            else {
                                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                                    label: stat.label,
                                                    value: stat.value,
                                                    icon: stat.icon,
                                                    color: stat.color,
                                                    trend: stat.trend
                                                });
                                            }
                                        }, { name: "StatCard" });
                                    }
                                    GridItem.pop();
                                };
                                observedDeepRender();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.dashboardData!.stats, forEachItemGenFunction, undefined, true, false);
                    }, ForEach);
                    ForEach.pop();
                    // 统计卡片网格
                    Grid.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 最近操作日志
                        Column.create();
                        // 最近操作日志
                        Column.width('100%');
                        // 最近操作日志
                        Column.backgroundColor('#FFFFFF');
                        // 最近操作日志
                        Column.borderRadius(8);
                        // 最近操作日志
                        Column.padding(16);
                        // 最近操作日志
                        Column.margin({ left: 16, right: 16, top: 12 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.margin({ bottom: 12 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('最近操作');
                        Text.fontSize(16);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('查看全部 >');
                        Text.fontSize(12);
                        Text.fontColor('#1677FF');
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.dashboardData!.recent_logs.length === 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('暂无操作记录');
                                    Text.fontSize(13);
                                    Text.fontColor('#999999');
                                    Text.width('100%');
                                    Text.textAlign(TextAlign.Center);
                                    Text.padding({ top: 24, bottom: 24 });
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const log = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Row.create();
                                            Row.width('100%');
                                            Row.height(48);
                                            Row.border({ width: { bottom: 0.5 }, color: '#EEEEEE' });
                                        }, Row);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Circle.create({ width: 32, height: 32 });
                                            Circle.fill('#E6F0FF');
                                        }, Circle);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Column.create();
                                            Column.alignItems(HorizontalAlign.Start);
                                            Column.margin({ left: 8 });
                                            Column.layoutWeight(1);
                                        }, Column);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(log.action);
                                            Text.fontSize(13);
                                            Text.fontColor('#333333');
                                        }, Text);
                                        Text.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(log.created_at ?? '');
                                            Text.fontSize(11);
                                            Text.fontColor('#999999');
                                            Text.margin({ top: 2 });
                                        }, Text);
                                        Text.pop();
                                        Column.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(log.ip ?? '');
                                            Text.fontSize(11);
                                            Text.fontColor('#999999');
                                        }, Text);
                                        Text.pop();
                                        Row.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.dashboardData!.recent_logs.slice(0, 8), forEachItemGenFunction);
                                }, ForEach);
                                ForEach.pop();
                            });
                        }
                    }, If);
                    If.pop();
                    // 最近操作日志
                    Column.pop();
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new 
                                // 底部版权
                                CopyrightBar(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/DashboardPage.ets", line: 163, col: 13 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {};
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {});
                            }
                        }, { name: "CopyrightBar" });
                    }
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
        return "DashboardPage";
    }
}
registerNamedRoute(() => new DashboardPage(undefined, {}), "", { bundleName: "xyz.erik.openadmin", moduleName: "entry", pagePath: "pages/DashboardPage", pageFullPath: "entry/src/main/ets/pages/DashboardPage", integratedHsp: "false", moduleType: "followWithHap" });
