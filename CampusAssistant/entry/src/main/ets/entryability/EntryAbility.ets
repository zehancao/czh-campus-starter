/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppStore } from '../service/AppStore';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private selectPage: string = '';
  private windowStage_: window.WindowStage | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppStore.getInstance().setContext(this.context);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.parseWidgetRouter(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    this.parseWidgetRouter(want);
    if (this.windowStage_ !== undefined) {
      this.loadTargetPage(this.windowStage_);
    }
  }

  private parseWidgetRouter(want: Want): void {
    const paramsStr = want.parameters?.params;
    if (paramsStr !== undefined && paramsStr !== null && typeof paramsStr === 'string') {
      try {
        const params: Record<string, string> = JSON.parse(paramsStr) as Record<string, string>;
        const target = params['targetPage'];
        if (target !== undefined && target.length > 0) {
          this.selectPage = target;
          hilog.info(DOMAIN, 'testTag', 'Widget router targetPage: %{public}s', this.selectPage);
        }
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', 'Failed to parse widget params');
      }
    }
  }

  private loadTargetPage(windowStage: window.WindowStage): void {
    if (this.selectPage.length > 0) {
      hilog.info(DOMAIN, 'testTag', 'Loading target page: %{public}s', this.selectPage);
      windowStage.loadContent(this.selectPage, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load target page. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading target page.');
        this.selectPage = '';
      });
    } else {
      windowStage.loadContent('pages/LoginPage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    this.windowStage_ = windowStage;
    this.loadTargetPage(windowStage);
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    this.windowStage_ = undefined;
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}