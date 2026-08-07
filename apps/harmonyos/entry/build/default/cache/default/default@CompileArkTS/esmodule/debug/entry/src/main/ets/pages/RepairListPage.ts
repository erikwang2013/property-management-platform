if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface RepairListPage_Params {
    repairs?: RepairOrder[];
    loading?: boolean;
    statusFilter?: string;
    api?: ApiService;
}
import router from "@ohos:router";
import { ApiService } from "@bundle:com.erik.property.owner/entry/ets/services/ApiService";
import type { RepairOrder } from '../model/Models';
class RepairListPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__repairs = new ObservedPropertyObjectPU([], this, "repairs");
        this.__loading = new ObservedPropertySimplePU(true, this, "loading");
        this.__statusFilter = new ObservedPropertySimplePU('', this, "statusFilter");
        this.api = ApiService.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: RepairListPage_Params) {
        if (params.repairs !== undefined) {
            this.repairs = params.repairs;
        }
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.statusFilter !== undefined) {
            this.statusFilter = params.statusFilter;
        }
        if (params.api !== undefined) {
            this.api = params.api;
        }
    }
    updateStateVars(params: RepairListPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__repairs.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
        this.__statusFilter.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__repairs.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        this.__statusFilter.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __repairs: ObservedPropertyObjectPU<RepairOrder[]>;
    get repairs() {
        return this.__repairs.get();
    }
    set repairs(newValue: RepairOrder[]) {
        this.__repairs.set(newValue);
    }
    private __loading: ObservedPropertySimplePU<boolean>;
    get loading() {
        return this.__loading.get();
    }
    set loading(newValue: boolean) {
        this.__loading.set(newValue);
    }
    private __statusFilter: ObservedPropertySimplePU<string>;
    get statusFilter() {
        return this.__statusFilter.get();
    }
    set statusFilter(newValue: string) {
        this.__statusFilter.set(newValue);
    }
    private api: ApiService;
    async aboutToAppear(): Promise<void> {
        await this.api.init();
        this.loadRepairs();
    }
    async loadRepairs(): Promise<void> {
        this.loading = true;
        try {
            let path = '/service/repairs?page=1&per_page=50';
            if (this.statusFilter)
                path += `&status=${this.statusFilter}`;
            const resp = await this.api.get(path) as Record<string, Object>;
            if (resp['code'] === 0) {
                this.repairs = (resp['data'] as RepairOrder[]) || [];
            }
        }
        catch (e) { }
        this.loading = false;
    }
    statusLabel(status: number): string {
        const labels: Record<number, string> = { 0: '待处理', 1: '已分配', 2: '维修中', 3: '已完成', 4: '已评价', 5: '已取消' };
        return labels[status] || '未知';
    }
    categoryLabel(cat: number): string {
        const labels: Record<number, string> = { 1: '水电', 2: '门窗', 3: '管道', 4: '墙面', 5: '家电', 6: '电梯', 7: '其他' };
        return labels[cat] || '其他';
    }
    urgencyLabel(u: number): string {
        const labels: Record<number, string> = { 0: '普通', 1: '紧急', 2: '非常紧急' };
        return labels[u] || '普通';
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
            Text.create('报修记录');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('提交报修');
            Text.fontSize(14);
            Text.fontColor('#007AFF');
            Text.onClick(() => { router.pushUrl({ url: 'pages/RepairSubmitPage' }); });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Filter row
            Row.create();
            // Filter row
            Row.width('100%');
            // Filter row
            Row.padding({ left: 16, right: 16, top: 8, bottom: 8 });
        }, Row);
        this.filterChip.bind(this)('全部', '');
        this.filterChip.bind(this)('待处理', '0');
        this.filterChip.bind(this)('处理中', '1');
        this.filterChip.bind(this)('已完成', '3');
        // Filter row
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
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create();
                        List.layoutWeight(1);
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const r = _item;
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
                                        Text.create(this.categoryLabel(r.category));
                                        Text.fontSize(14);
                                        Text.fontWeight(FontWeight.Medium);
                                    }, Text);
                                    Text.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Blank.create();
                                    }, Blank);
                                    Blank.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(this.statusLabel(r.status));
                                        Text.fontSize(11);
                                        Text.fontColor('#FFF');
                                        Text.backgroundColor('#007AFF');
                                        Text.borderRadius(4);
                                        Text.padding({ left: 8, right: 8, top: 2, bottom: 2 });
                                    }, Text);
                                    Text.pop();
                                    Row.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Row.create();
                                        Row.width('100%');
                                        Row.margin({ top: 4 });
                                    }, Row);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(`${r.room_number} | ${this.urgencyLabel(r.urgency)}`);
                                        Text.fontSize(12);
                                        Text.fontColor('#999');
                                    }, Text);
                                    Text.pop();
                                    Row.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(r.description || '');
                                        Text.fontSize(13);
                                        Text.fontColor('#333');
                                        Text.margin({ top: 4 });
                                        Text.maxLines(2);
                                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                                    }, Text);
                                    Text.pop();
                                    Column.pop();
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.repairs, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    filterChip(label: string, status: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(13);
            Text.fontColor(this.statusFilter === status ? '#FFF' : '#333');
            Text.backgroundColor(this.statusFilter === status ? '#007AFF' : '#E8E8E8');
            Text.borderRadius(16);
            Text.padding({ left: 12, right: 12, top: 4, bottom: 4 });
            Text.margin({ right: 8 });
            Text.onClick(() => { this.statusFilter = status; this.loadRepairs(); });
        }, Text);
        Text.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "RepairListPage";
    }
}
registerNamedRoute(() => new RepairListPage(undefined, {}), "", { bundleName: "com.erik.property.owner", moduleName: "entry", pagePath: "pages/RepairListPage", pageFullPath: "entry/src/main/ets/pages/RepairListPage", integratedHsp: "false", moduleType: "followWithHap" });
