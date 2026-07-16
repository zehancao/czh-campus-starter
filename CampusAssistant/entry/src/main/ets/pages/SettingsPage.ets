/**
 * 设置页面
 */

import { router } from '@kit.ArkUI'

@Entry
@Component
struct SettingsPage {
  @State cacheSize: string = '0MB'

  aboutToAppear(): void {
    // TODO: 计算缓存大小
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => { router.back() })
        Text('设置').fontSize(18).fontWeight(FontWeight.Medium).margin({ left: 8 })
      }
      .width('100%').padding(16)

      // 第一组
      Column() {
        this.MenuItem('账号安全', () => { router.pushUrl({ url: 'pages/AccountSecurityPage' }) })
        this.Divider()
        this.MenuItem('消息通知', () => { router.pushUrl({ url: 'pages/NotificationSettingsPage' }) })
      }
      .width('90%').padding(12)
      .backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

      // 第二组
      Column() {
        Row() {
          Text('清除缓存').fontSize(16)
          Blank()
          Text(this.cacheSize).fontSize(14).fontColor('#999')
        }
        .width('100%').padding({ top: 12, bottom: 12 })
        .onClick(() => { this.clearCache() })

        this.Divider()

        this.MenuItem('关于智能校园助手', () => {
          AlertDialog.show({
            title: '关于',
            message: '智能校园助手 v1.0.0\n\n让校园生活更便捷'
          })
        })
      }
      .width('90%').padding(12)
      .backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
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

  clearCache(): void {
    // TODO: 清除缓存逻辑
    this.cacheSize = '0MB'
    AlertDialog.show({ message: '缓存已清除' })
  }
}
