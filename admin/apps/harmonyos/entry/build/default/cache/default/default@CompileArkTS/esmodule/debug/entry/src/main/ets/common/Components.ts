if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface CopyrightBar_Params {
}
interface ErrorView_Params {
    message?: string;
    onRetry?: () => void;
}
interface EmptyView_Params {
    message?: string;
}
interface LoadingView_Params {
    message?: string;
}
interface StatCard_Params {
    label?: string;
    value?: string;
    icon?: string;
    color?: string;
    trend?: number | null;
}
export class StatCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__label = new SynchedPropertySimpleOneWayPU(params.label, this, "label");
        this.__value = new SynchedPropertySimpleOneWayPU(params.value, this, "value");
        this.__icon = new SynchedPropertySimpleOneWayPU(params.icon, this, "icon");
        this.__color = new SynchedPropertySimpleOneWayPU(params.color, this, "color");
        this.__trend = new SynchedPropertyObjectOneWayPU(params.trend, this, "trend");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: StatCard_Params) {
        if (params.label === undefined) {
            this.__label.set('');
        }
        if (params.value === undefined) {
            this.__value.set('');
        }
        if (params.icon === undefined) {
            this.__icon.set('people');
        }
        if (params.color === undefined) {
            this.__color.set('#1677FF');
        }
        if (params.trend === undefined) {
            this.__trend.set(null);
        }
    }
    updateStateVars(params: StatCard_Params) {
        this.__label.reset(params.label);
        this.__value.reset(params.value);
        this.__icon.reset(params.icon);
        this.__color.reset(params.color);
        this.__trend.reset(params.trend);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__label.purgeDependencyOnElmtId(rmElmtId);
        this.__value.purgeDependencyOnElmtId(rmElmtId);
        this.__icon.purgeDependencyOnElmtId(rmElmtId);
        this.__color.purgeDependencyOnElmtId(rmElmtId);
        this.__trend.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__label.aboutToBeDeleted();
        this.__value.aboutToBeDeleted();
        this.__icon.aboutToBeDeleted();
        this.__color.aboutToBeDeleted();
        this.__trend.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __label: SynchedPropertySimpleOneWayPU<string>;
    get label() {
        return this.__label.get();
    }
    set label(newValue: string) {
        this.__label.set(newValue);
    }
    private __value: SynchedPropertySimpleOneWayPU<string>;
    get value() {
        return this.__value.get();
    }
    set value(newValue: string) {
        this.__value.set(newValue);
    }
    private __icon: SynchedPropertySimpleOneWayPU<string>;
    get icon() {
        return this.__icon.get();
    }
    set icon(newValue: string) {
        this.__icon.set(newValue);
    }
    private __color: SynchedPropertySimpleOneWayPU<string>;
    get color() {
        return this.__color.get();
    }
    set color(newValue: string) {
        this.__color.set(newValue);
    }
    private __trend: SynchedPropertySimpleOneWayPU<number | null>;
    get trend() {
        return this.__trend.get();
    }
    set trend(newValue: number | null) {
        this.__trend.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height(110);
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(8);
            Column.shadow({ radius: 4, color: '#00000010', offsetY: 2 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.justifyContent(FlexAlign.Start);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": -1, "type": 30000, params: [`${this.icon}.png`], "bundleName": "xyz.erik.openadmin", "moduleName": "entry" });
            Image.width(20);
            Image.height(20);
            Image.fillColor(this.color);
        }, Image);
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.label);
            Text.fontSize(12);
            Text.fontColor('#666666');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.value);
            Text.fontSize(24);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.color);
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
export class LoadingView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__message = new SynchedPropertySimpleOneWayPU(params.message, this, "message");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: LoadingView_Params) {
        if (params.message === undefined) {
            this.__message.set('加载中...');
        }
    }
    updateStateVars(params: LoadingView_Params) {
        this.__message.reset(params.message);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__message.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__message.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __message: SynchedPropertySimpleOneWayPU<string>;
    get message() {
        return this.__message.get();
    }
    set message(newValue: string) {
        this.__message.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.justifyContent(FlexAlign.Center);
            Column.width('100%');
            Column.height('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            LoadingProgress.create();
            LoadingProgress.width(40);
            LoadingProgress.height(40);
            LoadingProgress.color('#1677FF');
        }, LoadingProgress);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.message);
            Text.fontSize(14);
            Text.fontColor('#999999');
            Text.margin({ top: 12 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
export class EmptyView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__message = new SynchedPropertySimpleOneWayPU(params.message, this, "message");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: EmptyView_Params) {
        if (params.message === undefined) {
            this.__message.set('暂无数据');
        }
    }
    updateStateVars(params: EmptyView_Params) {
        this.__message.reset(params.message);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__message.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__message.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __message: SynchedPropertySimpleOneWayPU<string>;
    get message() {
        return this.__message.get();
    }
    set message(newValue: string) {
        this.__message.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.justifyContent(FlexAlign.Center);
            Column.width('100%');
            Column.height('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['empty.png'], "bundleName": "xyz.erik.openadmin", "moduleName": "entry" });
            Image.width(120);
            Image.height(120);
            Image.objectFit(ImageFit.Contain);
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.message);
            Text.fontSize(14);
            Text.fontColor('#999999');
            Text.margin({ top: 12 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
export class ErrorView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__message = new SynchedPropertySimpleOneWayPU(params.message, this, "message");
        this.onRetry = undefined;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ErrorView_Params) {
        if (params.message === undefined) {
            this.__message.set('加载失败');
        }
        if (params.onRetry !== undefined) {
            this.onRetry = params.onRetry;
        }
    }
    updateStateVars(params: ErrorView_Params) {
        this.__message.reset(params.message);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__message.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__message.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __message: SynchedPropertySimpleOneWayPU<string>;
    get message() {
        return this.__message.get();
    }
    set message(newValue: string) {
        this.__message.set(newValue);
    }
    private onRetry?: () => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.justifyContent(FlexAlign.Center);
            Column.width('100%');
            Column.height('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.message);
            Text.fontSize(14);
            Text.fontColor('#999999');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('重试');
            Button.margin({ top: 12 });
            Button.fontSize(14);
            Button.onClick(() => {
                if (this.onRetry) {
                    this.onRetry();
                }
            });
        }, Button);
        Button.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
export class CopyrightBar extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: CopyrightBar_Params) {
    }
    updateStateVars(params: CopyrightBar_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('Copyright (c) 2026 erik — https://erik.xyz');
            Text.fontSize(11);
            Text.fontColor('#CCCCCC');
            Text.textAlign(TextAlign.Center);
            Text.width('100%');
            Text.padding({ top: 8, bottom: 8 });
        }, Text);
        Text.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
