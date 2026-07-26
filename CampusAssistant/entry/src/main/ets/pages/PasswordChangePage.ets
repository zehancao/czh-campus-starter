/**
 * 修改密码页
 * 流程：Step1 验证原密码 → Step2 输入新密码 + 确认密码
 */

import { router } from '@kit.ArkUI'
import { ApiService, ApiResult } from '../service/ApiService'
import { Theme, ShadowStyle } from '../common/Theme'
import { NavHeader } from '../common/NavHeader'

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

  /** 验证原密码环节不再调用 changePassword(old, old)（会把密码改成自身、有副作用），
   *  仅做非空校验后进入第二步；真正的原密码校验在 submitNewPassword 调用
   *  changePassword(old, new) 时由后端一次性完成。
   */
  private verifyOldPassword(): void {
    const old: string = this.oldPassword.trim()
    if (old.length === 0) {
      this.errorMsg = '请输入原密码'
      return
    }
    this.errorMsg = ''
    this.step = 1
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
      NavHeader({ title: '修改密码' })

      // 步骤指示器
      Row() {
        this.StepDot(1, this.step >= 0, '验证身份')
        Row().width(52).height(2).backgroundColor(this.step >= 1 ? Theme.primary : Theme.textDisabled)
        this.StepDot(2, this.step >= 1, '设置新密码')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 30, bottom: 22 })

      // 表单区域
      Column() {
        if (this.step === 0) {
          this.Step1Content()
        } else {
          this.Step2Content()
        }
      }
      .width('88%')
      .padding(22)
      .backgroundColor(Theme.bgCard)
      .borderRadius(Theme.cardRadius)
      .shadow(ShadowStyle.nmRaisedLg)

      // 错误提示
      if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(13)
          .fontColor(Theme.danger)
          .width('88%')
          .margin({ top: 12 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  StepDot(num: number, active: boolean, label: string) {
    Column() {
      Text(`${num}`)
        .width(32).height(32)
        .borderRadius(16)
        .backgroundColor(active ? Theme.primary : Theme.textDisabled)
        .fontColor(Color.White)
        .fontSize(14)
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(11)
        .fontColor(active ? Theme.primary : Theme.textTertiary)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  Step1Content() {
    Text('请输入原密码以验证身份')
      .fontSize(15)
      .fontColor(Theme.textSecondary)
      .width('100%')
      .margin({ bottom: 20 })

    TextInput({ placeholder: '请输入原密码', text: this.oldPassword })
      .type(InputType.Password)
      .height(48)
      .fontSize(16)
      .fontColor(Theme.textPrimary)
      .placeholderColor(Theme.textDisabled)
      .backgroundColor(Theme.bgInput)
      .borderRadius(Theme.radiusPill)
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
      .backgroundColor(Theme.primary)
      .borderRadius(Theme.buttonRadius)
      .margin({ top: 20 })
      .shadow(ShadowStyle.sm)
      .enabled(!this.isLoading)
      .onClick(() => { this.verifyOldPassword() })
  }

  @Builder
  Step2Content() {
    Text('请设置新密码（至少6位）')
      .fontSize(15)
      .fontColor(Theme.textSecondary)
      .width('100%')
      .margin({ bottom: 20 })

    TextInput({ placeholder: '请输入新密码', text: this.newPassword })
      .type(InputType.Password)
      .height(48)
      .fontSize(16)
      .fontColor(Theme.textPrimary)
      .placeholderColor(Theme.textDisabled)
      .backgroundColor(Theme.bgInput)
      .borderRadius(Theme.radiusPill)
      .padding({ left: 14, right: 14 })
      .onChange((value: string) => {
        this.newPassword = value
        this.errorMsg = ''
      })

    TextInput({ placeholder: '请再次输入新密码', text: this.confirmPassword })
      .type(InputType.Password)
      .height(48)
      .fontSize(16)
      .fontColor(Theme.textPrimary)
      .placeholderColor(Theme.textDisabled)
      .backgroundColor(Theme.bgInput)
      .borderRadius(Theme.radiusPill)
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
      .backgroundColor(Theme.primary)
      .borderRadius(Theme.buttonRadius)
      .margin({ top: 20 })
      .shadow(ShadowStyle.sm)
      .enabled(!this.isLoading)
      .onClick(() => { this.submitNewPassword() })

    Button('返回上一步')
      .width('100%')
      .height(44)
      .fontSize(16)
      .fontColor(Theme.primary)
      .backgroundColor(Theme.bgCard)
      .borderRadius(Theme.buttonRadius)
      .margin({ top: 10 })
      .shadow(ShadowStyle.sm)
      .onClick(() => {
        this.step = 0
        this.newPassword = ''
        this.confirmPassword = ''
        this.errorMsg = ''
      })
  }
}
