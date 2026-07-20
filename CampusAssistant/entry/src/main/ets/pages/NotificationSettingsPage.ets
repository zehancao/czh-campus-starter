/**
 * 消息通知设置页
 */

import { router } from '@kit.ArkUI'
import { Theme, ShadowStyle } from '../common/Theme'
import { NavHeader } from '../common/NavHeader'

@Entry
@Component
struct NotificationSettingsPage {
  @State academicPush: boolean = true
  @State systemPush: boolean = true
  @State doNotDisturb: boolean = false
  @State dndStart: string = '22:00'
  @State dndEnd: string = '08:00'

  build() {
    Column() {
      NavHeader({ title: '通知设置' })

      Column() {
        this.ToggleItem('教务通知推送', this.academicPush, (v: boolean) => { this.academicPush = v })
        this.Divider()
        this.ToggleItem('系统通知推送', this.systemPush, (v: boolean) => { this.systemPush = v })
      }
      .width('90%').padding(12)
      .backgroundColor(Theme.bgCard).borderRadius(12).margin({ top: 12 })
      .shadow(ShadowStyle.sm)

      Column() {
        this.ToggleItem('免打扰', this.doNotDisturb, (v: boolean) => { this.doNotDisturb = v })
        if (this.doNotDisturb) {
          this.Divider()
          Row() {
            Text('免打扰时段').fontSize(16)
            Blank()
            Text(this.dndStart).fontSize(14)
            Text(' - ').fontSize(14)
            Text(this.dndEnd).fontSize(14)
          }
          .width('100%').padding({ top: 12, bottom: 12 })
        }
      }
      .width('90%').padding(12)
      .backgroundColor(Theme.bgCard).borderRadius(12).margin({ top: 12 })
      .shadow(ShadowStyle.sm)
    }
    .width('100%').height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder ToggleItem(label: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label).fontSize(16)
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange(onChange)
    }
    .width('100%').padding({ top: 10, bottom: 10 })
  }

  @Builder Divider() {
    Row().width('100%').height(0.5).backgroundColor(Theme.border)
  }
}
