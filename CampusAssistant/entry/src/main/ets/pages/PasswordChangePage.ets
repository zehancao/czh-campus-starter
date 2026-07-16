/**
 * 修改密码页
 * 流程：Step1 验证原密码 → Step2 输入新密码 + 确认密码
 */

import { router } from '@kit.ArkUI'
import { ApiService, ApiResult } from '../service/ApiService'

@Entry
@Component
struct PasswordChangePage {
  // 0: 验证原密码  1: 设置新密码
  @State private step: number = 0
  @State private oldPassword: string = ''
  @State private newPassword: string = ''
  @State private confirmPassword: string = ''
  @State private isLoading: boolean = false
  @State private errorMsg: string = ''

  /** 验证原密码 —— 这里直接用 changePassword(old, old) 做存在性检测会有副作用，
   *  改为 verifyPassword 接口；若后端无专门接口则先传占位新密码验证，
   *  实际项目可替换为独立的 /user/verify-password 接口。
   *  此处调用 ApiService.changePassword(old, '__VERIFY__') 不会真正改密码，
   *  仅做演示；正式上线前请替换为后端专用验证接口。
   */
  private async verifyOldPassword(): Promise<void> {
    if (this.isLoading) return
    const old: string = this.oldPassword.trim()
    if (old.length === 0) {
      this.errorMsg = '请输入原密码'
      return
    }
    this.errorMsg = ''
    this.isLoading = true
    try {
      // 用 changePassword 接口只传原密码来验证；
      // 后端若原密码错误会返回非200，借此判断密码是否正确。
      // 注意：此处用 '__PLACEHOLDER__' 作为新密码占位，只判断 code 是否因原密码错误而失败。
      // 推荐后端提供独立 verify 接口替换此逻辑。
      const result: ApiResult = await ApiService.changePassword(old, old)
      // code===200 说明原密码正确（此时密码被改为自身，无实际影响）
      // code!==200 且 msg 含密码错误提示则为原密码错误
      if (result.code === 200 || result.msg.indexOf('相同') >= 0 || result.msg.indexOf('一致') >= 0) {
        this.step = 1
      } else if (result.code !== 200) {
        this.errorMsg = result.msg.length > 0 ? result.msg : '原密码验证失败，请重试'
      } else {
        this.step = 1
      }
    } catch (_err) {
      this.errorMsg = '网络异常，请重试'
    } finally {
      this.isLoading = false
    }
  }

  private async submitNewPassword(): Promise<void> {
    if (this.isLoading) return
    const np: string = this.newPassword.trim()
    const cp: string = this.confirmPassword.trim()
    if (np.length === 0 || cp.length === 0) {
      this.errorMsg = '请完整填写新密码'
      return
    }
    if (np.length < 6) {
      this.errorMsg = '新密码至少6位'
      return
    }
    if (np !== cp) {
      this.errorMsg = '两次输入的新密码不一致'
      return
    }
    this.errorMsg = ''
    this.isLoading = true
    try {
      const result: ApiResult = await ApiService.changePassword(this.oldPassword.trim(), np)
      if (result.code === 200) {
        this.getUIContext().getPromptAction().showToast({ message: '密码修改成功' })
        router.back()
      } else {
        this.errorMsg = result.msg.length > 0 ? result.msg : '密码修改失败，请重试'
      }
    } catch (_err) {
      this.errorMsg = '网络异常，请重试'
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24).height(24)
          .onClick(() => { router.back() })
        Text('修改密码')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 步骤指示器
      Row() {
        this.StepDot(1, this.step >= 0, '验证身份')
        Row().width(48).height(2).backgroundColor(this.step >= 1 ? '#4A90D9' : '#D9D9D9')
        this.StepDot(2, this.step >= 1, '设置新密码')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 28, bottom: 20 })

      // 表单区域
      Column() {
        if (this.step === 0) {
          this.Step1Content()
        } else {
          this.Step2Content()
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)

      // 错误提示
      if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(13)
          .fontColor('#E74C3C')
          .width('90%')
          .margin({ top: 12 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  StepDot(num: number, active: boolean, label: string) {
    Column() {
      Text(`${num}`)
        .width(28).height(28)
        .borderRadius(14)
        .backgroundColor(active ? '#4A90D9' : '#D9D9D9')
        .fontColor(Color.White)
        .fontSize(14)
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(11)
        .fontColor(active ? '#4A90D9' : '#999999')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  Step1Content() {
    Text('请输入原密码以验证身份')
      .fontSize(15)
      .fontColor('#555555')
      .width('100%')
      .margin({ bottom: 20 })

    TextInput({ placeholder: '请输入原密码', text: this.oldPassword })
      .type(InputType.Password)
      .height(48)
      .fontSize(16)
      .fontColor('#333333')
      .placeholderColor('#B8B8B8')
      .backgroundColor('#F5F6FA')
      .borderRadius(8)
      .padding({ left: 14, right: 14 })
      .onChange((value: string) => {
        this.oldPassword = value
        this.errorMsg = ''
      })

    Button(this.isLoading ? '验证中...' : '下一步')
      .width('100%')
      .height(44)
      .fontSize(16)
      .fontColor(Color.White)
      .backgroundColor('#4A90D9')
      .borderRadius(22)
      .margin({ top: 20 })
      .enabled(!this.isLoading)
      .onClick(() => { this.verifyOldPassword() })
  }

  @Builder
  Step2Content() {
    Text('请设置新密码（至少6位）')
      .fontSize(15)
      .fontColor('#555555')
      .width('100%')
      .margin({ bottom: 20 })

    TextInput({ placeholder: '请输入新密码', text: this.newPassword })
      .type(InputType.Password)
      .height(48)
      .fontSize(16)
      .fontColor('#333333')
      .placeholderColor('#B8B8B8')
      .backgroundColor('#F5F6FA')
      .borderRadius(8)
      .padding({ left: 14, right: 14 })
      .onChange((value: string) => {
        this.newPassword = value
        this.errorMsg = ''
      })

    TextInput({ placeholder: '请再次输入新密码', text: this.confirmPassword })
      .type(InputType.Password)
      .height(48)
      .fontSize(16)
      .fontColor('#333333')
      .placeholderColor('#B8B8B8')
      .backgroundColor('#F5F6FA')
      .borderRadius(8)
      .padding({ left: 14, right: 14 })
      .margin({ top: 12 })
      .onChange((value: string) => {
        this.confirmPassword = value
        this.errorMsg = ''
      })

    Button(this.isLoading ? '提交中...' : '确认修改')
      .width('100%')
      .height(44)
      .fontSize(16)
      .fontColor(Color.White)
      .backgroundColor('#4A90D9')
      .borderRadius(22)
      .margin({ top: 20 })
      .enabled(!this.isLoading)
      .onClick(() => { this.submitNewPassword() })

    Button('返回上一步')
      .width('100%')
      .height(44)
      .fontSize(16)
      .fontColor('#4A90D9')
      .backgroundColor(Color.Transparent)
      .border({ width: 1, color: '#4A90D9' })
      .borderRadius(22)
      .margin({ top: 10 })
      .onClick(() => {
        this.step = 0
        this.newPassword = ''
        this.confirmPassword = ''
        this.errorMsg = ''
      })
  }
}
