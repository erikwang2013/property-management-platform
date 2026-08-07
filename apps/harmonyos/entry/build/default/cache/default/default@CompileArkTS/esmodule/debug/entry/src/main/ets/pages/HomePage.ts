if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HomePage_Params {
    announcements?: Announcement[];
    balance?: number;
    pendingRepairs?: number;
    rooms?: number;
    api?: ApiService;
}
import router from "@ohos:router";
import { ApiService } from "@bundle:com.erik.property.owner/entry/ets/services/ApiService";
import type { Announcement } from '../model/Models';
class HomePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__announcements = new ObservedPropertyObjectPU([], this, "announcements");
        this.__balance = new ObservedPropertySimplePU(0, this, "balance");
        this.__pendingRepairs = new ObservedPropertySimplePU(0, this, "pendingRepairs");
        this.__rooms = new ObservedPropertySimplePU(0, this, "rooms");
        this.api = ApiService.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HomePage_Params) {
        if (params.announcements !== undefined) {
            this.announcements = params.announcements;
        }
        if (params.balance !== undefined) {
            this.balance = params.balance;
        }
        if (params.pendingRepairs !== undefined) {
            this.pendingRepairs = params.pendingRepairs;
        }
        if (params.rooms !== undefined) {
            this.rooms = params.rooms;
        }
        if (params.api !== undefined) {
            this.api = params.api;
        }
    }
    updateStateVars(params: HomePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__announcements.purgeDependencyOnElmtId(rmElmtId);
        this.__balance.purgeDependencyOnElmtId(rmElmtId);
        this.__pendingRepairs.purgeDependencyOnElmtId(rmElmtId);
        this.__rooms.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__announcements.aboutToBeDeleted();
        this.__balance.aboutToBeDeleted();
        this.__pendingRepairs.aboutToBeDeleted();
        this.__rooms.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __announcements: ObservedPropertyObjectPU<Announcement[]>;
    get announcements() {
        return this.__announcements.get();
    }
    set announcements(newValue: Announcement[]) {
        this.__announcements.set(newValue);
    }
    private __balance: ObservedPropertySimplePU<number>;
    get balance() {
        return this.__balance.get();
    }
    set balance(newValue: number) {
        this.__balance.set(newValue);
    }
    private __pendingRepairs: ObservedPropertySimplePU<number>;
    get pendingRepairs() {
        return this.__pendingRepairs.get();
    }
    set pendingRepairs(newValue: number) {
        this.__pendingRepairs.set(newValue);
    }
    private __rooms: ObservedPropertySimplePU<number>;
    get rooms() {
        return this.__rooms.get();
    }
    set rooms(newValue: number) {
        this.__rooms.set(newValue);
    }
    private api: ApiService;
    async aboutToAppear(): Promise<void> {
        await this.api.init();
        this.loadDashboard();
    }
    async loadDashboard(): Promise<void> {
        try {
            const resp = await this.api.get('/service/home') as Record<string, Object>;
            if (resp['code'] === 0) {
                const data = resp['data'] as Record<string, Object>;
                this.balance = parseFloat(data['pending_amount'] as string) || 0;
                this.pendingRepairs = (data['repairing_count'] as number) || 0;
                this.rooms = (data['room_count'] as number) || 0;
                this.announcements = (data['announcements'] as Announcement[]) || [];
            }
        }
        catch (e) {
            console.error('Failed to load dashboard:', JSON.stringify(e));
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#F5F5F5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Title bar
            Row.create();
            // Title bar
            Row.width('100%');
            // Title bar
            Row.padding(16);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('物业管理平台');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('退出');
            Text.fontSize(14);
            Text.fontColor('#007AFF');
            Text.onClick(() => {
                router.replaceUrl({ url: 'pages/LoginPage' });
            });
        }, Text);
        Text.pop();
        // Title bar
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Stat cards
            Row.create();
            // Stat cards
            Row.width('100%');
            // Stat cards
            Row.padding({ left: 16, right: 16 });
            // Stat cards
            Row.justifyContent(FlexAlign.SpaceBetween);
        }, Row);
        this.statCard.bind(this)('待缴费用', `¥${this.balance.toFixed(2)}`, '#FF6B6B');
        this.statCard.bind(this)('维修工单', `${this.pendingRepairs}个`, '#4ECDC4');
        this.statCard.bind(this)('我的房产', `${this.rooms}套`, '#45B7D1');
        // Stat cards
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Announcements
            List.create();
            // Announcements
            List.layoutWeight(1);
            // Announcements
            List.margin({ top: 16 });
            // Announcements
            List.padding({ left: 16, right: 16 });
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const item = _item;
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
                            Row.padding(12);
                        }, Row);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.alignItems(HorizontalAlign.Start);
                            Column.layoutWeight(1);
                        }, Column);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(item.title);
                            Text.fontSize(16);
                            Text.fontWeight(FontWeight.Medium);
                            Text.maxLines(1);
                            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(item.published_at);
                            Text.fontSize(12);
                            Text.fontColor('#999');
                            Text.margin({ top: 4 });
                        }, Text);
                        Text.pop();
                        Column.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(this.categoryLabel(item.category));
                            Text.fontSize(11);
                            Text.fontColor('#FFF');
                            Text.backgroundColor('#007AFF');
                            Text.borderRadius(4);
                            Text.padding({ left: 8, right: 8, top: 2, bottom: 2 });
                        }, Text);
                        Text.pop();
                        Row.pop();
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, this.announcements, forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        // Announcements
        List.pop();
        Column.pop();
    }
    statCard(label: string, value: string, color: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('30%');
            Column.height(80);
            Column.justifyContent(FlexAlign.Center);
            Column.backgroundColor('#FFF');
            Column.borderRadius(8);
            Column.shadow({ radius: 4, color: '#00000010', offsetX: 0, offsetY: 2 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(value);
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(color);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(12);
            Text.fontColor('#999');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    categoryLabel(category: number): string {
        const labels: Record<number, string> = { 1: '通知', 2: '活动', 3: '公告' };
        return labels[category] || '通知';
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "HomePage";
    }
}
registerNamedRoute(() => new HomePage(undefined, {}), "", { bundleName: "com.erik.property.owner", moduleName: "entry", pagePath: "pages/HomePage", pageFullPath: "entry/src/main/ets/pages/HomePage", integratedHsp: "false", moduleType: "followWithHap" });
