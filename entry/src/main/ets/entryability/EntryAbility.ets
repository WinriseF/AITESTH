import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppDataSource } from '../common/AppDataSource'
const DOMAIN = 0x0000;
const TAG = 'testTag';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    let initialPage = 'pages/LoginPage'; // 默认启动页是登录页

    try {
      // 1. 初始化 AppDataSource
      AppDataSource.getInstance(this.context);
      hilog.info(DOMAIN, TAG, 'AppDataSource has been initialized successfully.');

      // 2. 检查是否存在已存储的Token
      const storedToken = await AppDataSource.getInstance().getToken();

      // 3. 如果Token存在且不为空，则修改启动页为主页
      if (storedToken) {
        hilog.info(DOMAIN, TAG, 'Found existing token. Setting initial page to Index.');
        initialPage = 'pages/Index';
      } else {
        hilog.info(DOMAIN, TAG, 'No token found. Setting initial page to LoginPage.');
      }

    } catch (err) {
      if (err instanceof Error) {
        hilog.error(DOMAIN, TAG, `Failed during app initialization: ${err.message}`);
      } else {
        hilog.error(DOMAIN, TAG, 'Failed during app initialization: An unknown error occurred.');
      }
    }

    // 4. 使用我们动态决定的 initialPage 来加载内容
    windowStage.loadContent(initialPage, (err) => {
      if (err?.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}