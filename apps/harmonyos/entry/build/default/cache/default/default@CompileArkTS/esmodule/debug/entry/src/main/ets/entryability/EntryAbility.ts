import UIAbility from "@ohos:app.ability.UIAbility";
import type Want from "@ohos:app.ability.Want";
import type AbilityConstant from "@ohos:app.ability.AbilityConstant";
import type window from "@ohos:window";
import hilog from "@ohos:hilog";
import preferences from "@ohos:data.preferences";
const TAG = 'EntryAbility';
export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        hilog.info(0x0000, TAG, 'Ability onCreate');
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        hilog.info(0x0000, TAG, 'Ability onWindowStageCreate');
        // 已登录则跳过登录页直接进入首页（token 存于 preferences 'property_portal' 的 access_token 键）
        this.loadStartPage(windowStage);
    }
    private async loadStartPage(windowStage: window.WindowStage): Promise<void> {
        let startPage = 'pages/LoginPage';
        try {
            const prefs = await preferences.getPreferences(this.context, 'property_portal');
            const token = (await prefs.get('access_token', '')) as string;
            if (token.length > 0) {
                startPage = 'pages/HomePage';
            }
        }
        catch (e) {
            hilog.error(0x0000, TAG, `Failed to read token: ${JSON.stringify(e)}`);
        }
        windowStage.loadContent(startPage, (err) => {
            if (err.code) {
                hilog.error(0x0000, TAG, `Failed to load content: ${err.code}`);
                return;
            }
            hilog.info(0x0000, TAG, 'Succeeded in loading content');
        });
    }
    onWindowStageDestroy(): void {
        hilog.info(0x0000, TAG, 'Ability onWindowStageDestroy');
    }
    onForeground(): void {
        hilog.info(0x0000, TAG, 'Ability onForeground');
    }
    onBackground(): void {
        hilog.info(0x0000, TAG, 'Ability onBackground');
    }
    onDestroy(): void {
        hilog.info(0x0000, TAG, 'Ability onDestroy');
    }
}
