import { AppStore } from '../service/AppStore';
import { ApiService, ApiResult } from '../service/ApiService';

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

      Text('智能校园助手')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Text('Campus Assistant')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 60 })

      Column() {
        TextInput({ placeholder: '请输入学号', text: this.studentId })
          .type(InputType.Normal)
          .height(48)
          .fontSize(16)
          .placeholderColor('#CCCCCC')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.studentId = value;
            this.errorMsg = '';
          })

        Blank().height(16)

        TextInput({ placeholder: '请输入密码', text: this.password })
          .type(InputType.Password)
          .height(48)
          .fontSize(16)
          .placeholderColor('#CCCCCC')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.password = value;
            this.errorMsg = '';
          })
      }
      .width('85%')

      if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(12)
          .fontColor('#FF4444')
          .margin({ top: 12 })
      }

      Blank().height(32)

      Button('登 录')
        .width('85%')
        .height(48)
        .fontSize(18)
        .fontColor(Color.White)
        .backgroundColor('#4A90D9')
        .borderRadius(24)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleLogin();
        })

      Blank().height(24)

      Row() {
        Text('还没有账号？')
          .fontSize(14)
          .fontColor('#999999')
        Text('立即注册')
          .fontSize(14)
          .fontColor('#4A90D9')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/RegisterPage' });
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
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
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' });
    } else {
      this.errorMsg = result.msg.length > 0 ? result.msg : '登录失败';
    }
  }
}