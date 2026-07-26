/**
 * 账号安全页
 * 包含：修改密码、退出登录、切换账号
 */

import { router } from '@kit.ArkUI'
import { AppStore } from '../service/AppStore'
import { Theme, ShadowStyle } from '../common/Theme'
import { NavHeader } from '../common/NavHeader'

@Entry
@Component
struct AccountSecurityPage {

  build() {
    Column() {
      NavHeader({ title: '账号安全' })

      Column() {
        this.MenuItem('修改密码', () => { router.pushUrl({ url: 'pages/PasswordChangePage' }) })
        this.Divider()
        this.MenuItem('切换账号', () => { this.switchAccount() })
      }
      .width('90%').padding(12)
      .backgroundColor(Theme.bgCard).borderRadius(Theme.cardRadius).margin({ top: 12 })
      .shadow(ShadowStyle.sm)

      // 退出登录
      Button('退出登录')
        .width('90%')
        .backgroundColor(Theme.danger)
        .fontColor(Color.White)
        .margin({ top: 24 })
        .onClick(() => { this.doLogout() })
    }
    .width('100%').height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder MenuItem(label: string, onClick: () => void) {
    Row() {
      Text(label).fontSize(16)
      Blank()
      Image($r('app.media.ic_arrow_right')).width(16).height(16)
    }
    .width('100%').padding({ top: 12, bottom: 12 })
    .onClick(onClick)
  }

  @Builder Divider() {
    Row().width('100%').height(0.5).backgroundColor(Theme.border)
  }

  async doLogout(): Promise<void> {
    AlertDialog.show({
      title: '确认退出',
      message: '确定要退出登录吗？',
      primaryButton: {
        value: '确定',
        action: () => {
          AppStore.getInstance().logout()
          router.replaceUrl({ url: 'pages/LoginPage' })
        }
      },
      secondaryButton: { value: '取消', action: () => {} }
    })
  }

  async switchAccount(): Promise<void> {
    AppStore.getInstance().logout()
    router.replaceUrl({ url: 'pages/LoginPage' })
  }
}
