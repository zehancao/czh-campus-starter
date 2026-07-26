import { router } from '@kit.ArkUI'
import { ApiService, ApiResult } from '../service/ApiService'
import { AppStore } from '../service/AppStore'
import { Theme, ShadowStyle } from '../common/Theme'
import { NavHeader } from '../common/NavHeader'

@Entry
@Component
struct SettingsPage {
  @State feedbackContent: string = ''
  @State contactInfo: string = ''
  @State sending: boolean = false

  build() {
    Column() {
      NavHeader({ title: '联系我们' })

      Column() {
        Text('您的反馈对我们非常重要')
          .fontSize(14)
          .fontColor(Theme.textTertiary)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '联系方式（选填，方便我们回复您）', text: this.contactInfo })
          .type(InputType.Normal)
          .height(44)
          .fontSize(14)
          .backgroundColor(Theme.bgInput)
          .borderRadius(Theme.radiusSm)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => { this.contactInfo = value })

        TextArea({ placeholder: '请输入您的反馈或建议...', text: this.feedbackContent })
          .height(160)
          .fontSize(14)
          .backgroundColor(Theme.bgInput)
          .borderRadius(Theme.radiusSm)
          .padding(12)
          .margin({ top: 12 })
          .onChange((value: string) => { this.feedbackContent = value })

        Button(this.sending ? '发送中...' : '提交反馈')
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(this.sending ? Theme.textDisabled : Theme.primary)
          .borderRadius(Theme.buttonRadius)
          .margin({ top: 20 })
          .enabled(!this.sending && this.feedbackContent.length > 0)
          .onClick(() => { this.submitFeedback() })
      }
      .width('90%')
      .padding(16)
      .backgroundColor(Theme.bgCard)
      .borderRadius(Theme.cardRadius)
      .margin({ top: 12 })
      .shadow(ShadowStyle.sm)
    }
    .width('100%').height('100%')
    .backgroundColor(Theme.bgPage)
  }

  async submitFeedback(): Promise<void> {
    this.sending = true;
    const store = AppStore.getInstance();
    const userName: string = store.userInfo.name.length > 0 ? store.userInfo.name : '匿名用户';
    const result: ApiResult = await ApiService.submitFeedback(userName, this.contactInfo, this.feedbackContent);
    this.sending = false;
    if (result.code === 200) {
      this.feedbackContent = '';
      this.contactInfo = '';
      AlertDialog.show({ message: '感谢您的反馈，我们会尽快处理！' });
    } else {
      AlertDialog.show({ message: result.msg });
    }
  }
}
