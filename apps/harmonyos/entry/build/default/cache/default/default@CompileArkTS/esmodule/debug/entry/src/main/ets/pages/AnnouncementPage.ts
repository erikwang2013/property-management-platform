if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface AnnouncementPage_Params {
    announcements?: Announcement[];
    loading?: boolean;
    selectedItem?: Announcement | null;
    api?: ApiService;
}
import { ApiService } from "@bundle:com.erik.property.owner/entry/ets/services/ApiService";
import type { Announcement } from '../model/Models';
class AnnouncementPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__announcements = new ObservedPropertyObjectPU([], this, "announcements");
        this.__loading = new ObservedPropertySimplePU(true, this, "loading");
        this.__selectedItem = new ObservedPropertyObjectPU(null, this, "selectedItem");
        this.api = ApiService.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: AnnouncementPage_Params) {
        if (params.announcements !== undefined) {
            this.announcements = params.announcements;
        }
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.selectedItem !== undefined) {
            this.selectedItem = params.selectedItem;
        }
        if (params.api !== undefined) {
            this.api = params.api;
        }
    }
    updateStateVars(params: AnnouncementPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__announcements.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedItem.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__announcements.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        this.__selectedItem.aboutToBeDeleted();
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
    private __loading: ObservedPropertySimplePU<boolean>;
    get loading() {
        return this.__loading.get();
    }
    set loading(newValue: boolean) {
        this.__loading.set(newValue);
    }
    private __selectedItem: ObservedPropertyObjectPU<Announcement | null>;
    get selectedItem() {
        return this.__selectedItem.get();
    }
    set selectedItem(newValue: Announcement | null) {
        this.__selectedItem.set(newValue);
    }
    private api: ApiService;
    async aboutToAppear(): Promise<void> {
        await this.api.init();
        this.loadList();
    }
    async loadList(): Promise<void> {
        this.loading = true;
        try {
            const resp = await this.api.get('/service/announcements?page=1&per_page=50') as Record<string, Object>;
            if (resp['code'] === 0) {
                this.announcements = (resp['data'] as Announcement[]) || [];
            }
        }
        catch (e) { }
        this.loading = false;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.selectedItem) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Detail view
                        Column.create();
                        // Detail view
                        Column.width('100%');
                        // Detail view
                        Column.height('100%');
                        // Detail view
                        Column.backgroundColor('#F5F5F5');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.padding(16);
                        Row.backgroundColor('#FFF');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('← 返回');
                        Text.fontSize(14);
                        Text.fontColor('#007AFF');
                        Text.onClick(() => { this.selectedItem = null; });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                    }, Blank);
                    Blank.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.padding(16);
                        Column.backgroundColor('#FFF');
                        Column.margin({ top: 8 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.selectedItem.title);
                        Text.fontSize(20);
                        Text.fontWeight(FontWeight.Bold);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.selectedItem.published_at);
                        Text.fontSize(12);
                        Text.fontColor('#999');
                        Text.margin({ top: 8 });
                    }, Text);
                    Text.pop();
                    Column.pop();
                    // Detail view
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // List view
                        Column.create();
                        // List view
                        Column.width('100%');
                        // List view
                        Column.height('100%');
                        // List view
                        Column.backgroundColor('#F5F5F5');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.padding(16);
                        Row.backgroundColor('#FFF');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('社区公告');
                        Text.fontSize(20);
                        Text.fontWeight(FontWeight.Bold);
                    }, Text);
                    Text.pop();
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
                                                    Row.padding(16);
                                                    Row.backgroundColor('#FFF');
                                                    Row.borderRadius(8);
                                                    Row.margin({ left: 16, right: 16, bottom: 8 });
                                                    Row.onClick(() => { this.selectedItem = item; });
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
                                                    Image.create({ "id": 16777236, "type": 20000, params: [], "bundleName": "com.erik.property.owner", "moduleName": "entry" });
                                                    Image.width(16);
                                                    Image.height(16);
                                                    Image.fillColor('#CCC');
                                                }, Image);
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
                                List.pop();
                            });
                        }
                    }, If);
                    If.pop();
                    // List view
                    Column.pop();
                });
            }
        }, If);
        If.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "AnnouncementPage";
    }
}
registerNamedRoute(() => new AnnouncementPage(undefined, {}), "", { bundleName: "com.erik.property.owner", moduleName: "entry", pagePath: "pages/AnnouncementPage", pageFullPath: "entry/src/main/ets/pages/AnnouncementPage", integratedHsp: "false", moduleType: "followWithHap" });
