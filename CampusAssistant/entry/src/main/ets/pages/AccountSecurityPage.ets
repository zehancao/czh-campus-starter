/**
 * 账号安全页
 * 包含：修改密码、退出登录、切换账号
 */

import { router } from '@kit.ArkUI'
import { AppStore } from '../service/AppStore'

@Entry
@Component
struct AccountSecurityPage {

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => { router.back() })
        Text('账号安全').fontSize(18).fontWeight(FontWeight.Medium).margin({ left: 8 })
      }
      .width('100%').padding(16)

      Column() {
        this.MenuItem('修改密码', () => { router.pushUrl({ url: 'pages/PasswordChangePage' }) })
        this.Divider()
        this.MenuItem('切换账号', () => { this.switchAccount() })
      }
      .width('90%').padding(12)
      .backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

      // 退出登录
      Button('退出登录')
        .width('90%')
        .backgroundColor('#FF4D4F')
        .fontColor(Color.White)
        .margin({ top: 24 })
        .onClick(() => { this.doLogout() })
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F5F5')
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
    Row().width('100%').height(0.5).backgroundColor('#F0F0F0')
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
