if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface FeeBillsPage_Params {
    bills?: FeeBill[];
    loading?: boolean;
    api?: ApiService;
}
import { ApiService } from "@bundle:com.erik.property.owner/entry/ets/services/ApiService";
import type { FeeBill } from '../model/Models';
class FeeBillsPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__bills = new ObservedPropertyObjectPU([], this, "bills");
        this.__loading = new ObservedPropertySimplePU(true, this, "loading");
        this.api = ApiService.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: FeeBillsPage_Params) {
        if (params.bills !== undefined) {
            this.bills = params.bills;
        }
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.api !== undefined) {
            this.api = params.api;
        }
    }
    updateStateVars(params: FeeBillsPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__bills.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__bills.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __bills: ObservedPropertyObjectPU<FeeBill[]>;
    get bills() {
        return this.__bills.get();
    }
    set bills(newValue: FeeBill[]) {
        this.__bills.set(newValue);
    }
    private __loading: ObservedPropertySimplePU<boolean>;
    get loading() {
        return this.__loading.get();
    }
    set loading(newValue: boolean) {
        this.__loading.set(newValue);
    }
    private api: ApiService;
    async aboutToAppear(): Promise<void> {
        await this.api.init();
        this.loadBills();
    }
    async loadBills(): Promise<void> {
        this.loading = true;
        try {
            const resp = await this.api.get('/service/fees/bills?page=1&per_page=50') as Record<string, Object>;
            if (resp['code'] === 0) {
                this.bills = (resp['data'] as FeeBill[]) || [];
            }
        }
        catch (e) {
            console.error('Failed to load bills:', JSON.stringify(e));
        }
        this.loading = false;
    }
    statusLabel(status: number): string {
        const labels: Record<number, string> = { 0: '待缴', 1: '已缴', 2: '逾期', 3: '部分缴纳' };
        return labels[status] || '未知';
    }
    statusColor(status: number): string {
        const colors: Record<number, string> = { 0: '#FF6B6B', 1: '#4ECDC4', 2: '#FF4444', 3: '#FFA500' };
        return colors[status] || '#999';
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
            Text.create('我的账单');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.loading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        LoadingProgress.create();
                        LoadingProgress.width(40);
                        LoadingProgress.height(40);
                    }, LoadingProgress);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('加载中...');
                        Text.fontSize(14);
                        Text.fontColor('#999');
                        Text.margin({ top: 8 });
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else if (this.bills.length === 0) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('暂无账单');
                        Text.fontSize(16);
                        Text.fontColor('#999');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create();
                        List.layoutWeight(1);
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const bill = _item;
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
                                        Column.create();
                                        Column.width('100%');
                                        Column.padding(12);
                                        Column.backgroundColor('#FFF');
                                        Column.borderRadius(8);
                                        Column.margin({ left: 16, right: 16, bottom: 8 });
                                    }, Column);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Row.create();
                                        Row.width('100%');
                                    }, Row);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(bill.fee_type_name);
                                        Text.fontSize(16);
                                        Text.fontWeight(FontWeight.Medium);
                                    }, Text);
                                    Text.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Blank.create();
                                    }, Blank);
                                    Blank.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(`¥${bill.amount.toFixed(2)}`);
                                        Text.fontSize(16);
                                        Text.fontWeight(FontWeight.Bold);
                                        Text.fontColor('#FF6B6B');
                                    }, Text);
                                    Text.pop();
                                    Row.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Row.create();
                                        Row.width('100%');
                                        Row.margin({ top: 4 });
                                    }, Row);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(`${bill.room_number} | 截止: ${bill.due_date}`);
                                        Text.fontSize(12);
                                        Text.fontColor('#999');
                                    }, Text);
                                    Text.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Blank.create();
                                    }, Blank);
                                    Blank.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(this.statusLabel(bill.status));
                                        Text.fontSize(11);
                                        Text.fontColor('#FFF');
                                        Text.backgroundColor(this.statusColor(bill.status));
                                        Text.borderRadius(4);
                                        Text.padding({ left: 8, right: 8, top: 2, bottom: 2 });
                                    }, Text);
                                    Text.pop();
                                    Row.pop();
                                    Column.pop();
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.bills, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
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
        return "FeeBillsPage";
    }
}
registerNamedRoute(() => new FeeBillsPage(undefined, {}), "", { bundleName: "com.erik.property.owner", moduleName: "entry", pagePath: "pages/FeeBillsPage", pageFullPath: "entry/src/main/ets/pages/FeeBillsPage", integratedHsp: "false", moduleType: "followWithHap" });
