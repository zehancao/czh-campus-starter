import { AppStore } from '../service/AppStore';
import { ApiService, ApiResult } from '../service/ApiService';
import { Theme, ShadowStyle } from '../common/Theme';

@Entry
@Component
struct LoginPage {
  @State studentId: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMsg: string = '';

  build() {
    Column() {
      Blank().height(80)

      Text('校园π')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textPrimary)
        .margin({ bottom: 8 })

      Text('Campus π')
        .fontSize(14)
        .fontColor(Theme.textTertiary)
        .margin({ bottom: 60 })

      Column() {
        Stack({ alignContent: Alignment.TopStart }) {
          Column()
            .width('100%').height('100%')
            .backgroundColor('#C8CFDA')
            .borderRadius(28)
          TextInput({ placeholder: '请输入学号', text: this.studentId })
            .type(InputType.Normal)
            .width('100%').height(48)
            .fontSize(16)
            .placeholderColor(Theme.textDisabled)
            .backgroundColor('#FFFFFF')
            .borderRadius(28)
            .padding({ left: 16, right: 16 })
            .margin({ right: 4, bottom: 4 })
            .onChange((value: string) => {
              this.studentId = value;
              this.errorMsg = '';
            })
        }
        .width('100%').height(52)
        .borderRadius(28)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
        })
        .clip(false)
        .shadow({ radius: 16, color: '#ABB3C0', offsetX: 0, offsetY: 4 })

        Blank().height(16)

        Stack({ alignContent: Alignment.TopStart }) {
          Column()
            .width('100%').height('100%')
            .backgroundColor('#C8CFDA')
            .borderRadius(28)
          TextInput({ placeholder: '请输入密码', text: this.password })
            .type(InputType.Password)
            .width('100%').height(48)
            .fontSize(16)
            .placeholderColor(Theme.textDisabled)
            .backgroundColor('#FFFFFF')
            .borderRadius(28)
            .padding({ left: 16, right: 16 })
            .margin({ right: 4, bottom: 4 })
            .onChange((value: string) => {
              this.password = value;
              this.errorMsg = '';
            })
        }
        .width('100%').height(52)
        .borderRadius(28)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
        })
        .clip(false)
        .shadow({ radius: 16, color: '#ABB3C0', offsetX: 0, offsetY: 4 })
      }
      .width('85%')

      if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(12)
          .fontColor(Theme.danger)
          .margin({ top: 12 })
      }

      Blank().height(32)

      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width('100%').height('100%')
          .backgroundColor('#C8CFDA')
          .borderRadius(28)
        Column() {
          Text('登 录')
            .fontSize(18)
            .fontColor(Theme.textPrimary)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%').height(48)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(28)
        .backgroundColor('#FFFFFF')
        .margin({ right: 4, bottom: 4 })
      }
      .width('85%').height(52)
      .borderRadius(28)
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
      })
      .clip(false)
      .shadow({ radius: 16, color: '#ABB3C0', offsetX: 0, offsetY: 4 })
      .enabled(!this.isLoading)
      .onClick(() => {
        this.handleLogin();
      })

      Blank().height(24)

      Row() {
        Text('还没有账号？')
          .fontSize(14)
          .fontColor(Theme.textTertiary)
        Text('立即注册')
          .fontSize(14)
          .fontColor(Theme.primary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/RegisterPage' });
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgCard)
  }

  private async handleLogin(): Promise<void> {
    if (this.studentId.length === 0) {
      this.errorMsg = '请输入学号';
      return;
    }
    if (this.password.length === 0) {
      this.errorMsg = '请输入密码';
      return;
    }
    this.isLoading = true;
    const result: ApiResult = await ApiService.login(this.studentId, this.password);
    this.isLoading = false;
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '登录成功' });
      AppStore.getInstance().pendingTab = 0;
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' });
    } else {
      this.errorMsg = result.msg.length > 0 ? result.msg : '登录失败';
    }
  }
}
