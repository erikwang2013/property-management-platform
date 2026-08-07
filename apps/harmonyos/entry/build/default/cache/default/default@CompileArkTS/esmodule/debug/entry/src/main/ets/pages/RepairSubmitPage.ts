if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface RepairSubmitPage_Params {
    category?: number;
    urgency?: number;
    description?: string;
    roomId?: string;
    api?: ApiService;
}
import router from "@ohos:router";
import { ApiService } from "@bundle:com.erik.property.owner/entry/ets/services/ApiService";
import type { RepairRequest } from '../model/Models';
class RepairSubmitPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__category = new ObservedPropertySimplePU(1, this, "category");
        this.__urgency = new ObservedPropertySimplePU(0, this, "urgency");
        this.__description = new ObservedPropertySimplePU('', this, "description");
        this.__roomId = new ObservedPropertySimplePU('', this, "roomId");
        this.api = ApiService.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: RepairSubmitPage_Params) {
        if (params.category !== undefined) {
            this.category = params.category;
        }
        if (params.urgency !== undefined) {
            this.urgency = params.urgency;
        }
        if (params.description !== undefined) {
            this.description = params.description;
        }
        if (params.roomId !== undefined) {
            this.roomId = params.roomId;
        }
        if (params.api !== undefined) {
            this.api = params.api;
        }
    }
    updateStateVars(params: RepairSubmitPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__category.purgeDependencyOnElmtId(rmElmtId);
        this.__urgency.purgeDependencyOnElmtId(rmElmtId);
        this.__description.purgeDependencyOnElmtId(rmElmtId);
        this.__roomId.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__category.aboutToBeDeleted();
        this.__urgency.aboutToBeDeleted();
        this.__description.aboutToBeDeleted();
        this.__roomId.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __category: ObservedPropertySimplePU<number>;
    get category() {
        return this.__category.get();
    }
    set category(newValue: number) {
        this.__category.set(newValue);
    }
    private __urgency: ObservedPropertySimplePU<number>;
    get urgency() {
        return this.__urgency.get();
    }
    set urgency(newValue: number) {
        this.__urgency.set(newValue);
    }
    private __description: ObservedPropertySimplePU<string>;
    get description() {
        return this.__description.get();
    }
    set description(newValue: string) {
        this.__description.set(newValue);
    }
    private __roomId: ObservedPropertySimplePU<string>;
    get roomId() {
        return this.__roomId.get();
    }
    set roomId(newValue: string) {
        this.__roomId.set(newValue);
    }
    private api: ApiService;
    async aboutToAppear(): Promise<void> {
        await this.api.init();
    }
    async submit(): Promise<void> {
        if (!this.description)
            return;
        try {
            let payload: RepairRequest = {
                category: this.category,
                urgency: this.urgency,
                description: this.description
            };
            if (this.roomId) {
                payload = {
                    category: this.category,
                    urgency: this.urgency,
                    description: this.description,
                    room_id: this.roomId
                };
            }
            const resp = await this.api.post('/service/repair', payload) as Record<string, Object>;
            if (resp['code'] === 0) {
                router.back();
            }
        }
        catch (e) {
            console.error('Submit failed:', JSON.stringify(e));
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
            Row.create();
            Row.width('100%');
            Row.padding(16);
            Row.backgroundColor('#FFF');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('提交报修');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFF');
            Column.margin({ top: 8 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('报修类型');
            Text.fontSize(14);
            Text.fontColor('#999');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.typeChip.bind(this)('水电', 1);
        this.typeChip.bind(this)('门窗', 2);
        this.typeChip.bind(this)('管道', 3);
        this.typeChip.bind(this)('其他', 7);
        Row.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFF');
            Column.margin({ top: 8 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('紧急程度');
            Text.fontSize(14);
            Text.fontColor('#999');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.urgencyChip.bind(this)('普通', 0);
        this.urgencyChip.bind(this)('紧急', 1);
        this.urgencyChip.bind(this)('非常紧急', 2);
        Row.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFF');
            Column.margin({ top: 8 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('问题描述');
            Text.fontSize(14);
            Text.fontColor('#999');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextArea.create({ placeholder: '请描述您遇到的问题...', text: this.description });
            TextArea.height(120);
            TextArea.onChange((value: string) => { this.description = value; });
        }, TextArea);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('提交报修');
            Button.width('90%');
            Button.margin({ top: 24 });
            Button.backgroundColor('#007AFF');
            Button.borderRadius(8);
            Button.onClick(() => { this.submit(); });
        }, Button);
        Button.pop();
        Column.pop();
    }
    typeChip(label: string, value: number, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(14);
            Text.fontColor(this.category === value ? '#FFF' : '#333');
            Text.backgroundColor(this.category === value ? '#007AFF' : '#E8E8E8');
            Text.borderRadius(8);
            Text.padding({ left: 16, right: 16, top: 8, bottom: 8 });
            Text.margin({ right: 8 });
            Text.onClick(() => { this.category = value; });
        }, Text);
        Text.pop();
    }
    urgencyChip(label: string, value: number, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(14);
            Text.fontColor(this.urgency === value ? '#FFF' : '#333');
            Text.backgroundColor(this.urgency === value ? '#007AFF' : '#E8E8E8');
            Text.borderRadius(8);
            Text.padding({ left: 16, right: 16, top: 8, bottom: 8 });
            Text.margin({ right: 8 });
            Text.onClick(() => { this.urgency = value; });
        }, Text);
        Text.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "RepairSubmitPage";
    }
}
registerNamedRoute(() => new RepairSubmitPage(undefined, {}), "", { bundleName: "com.erik.property.owner", moduleName: "entry", pagePath: "pages/RepairSubmitPage", pageFullPath: "entry/src/main/ets/pages/RepairSubmitPage", integratedHsp: "false", moduleType: "followWithHap" });
