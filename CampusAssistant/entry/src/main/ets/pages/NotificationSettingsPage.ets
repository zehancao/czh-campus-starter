/**
 * 消息通知设置页
 */

import { router } from '@kit.ArkUI'

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
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => { router.back() })
        Text('消息通知').fontSize(18).fontWeight(FontWeight.Medium).margin({ left: 8 })
      }
      .width('100%').padding(16)

      Column() {
        this.ToggleItem('教务通知推送', this.academicPush, (v: boolean) => { this.academicPush = v })
        this.Divider()
        this.ToggleItem('系统通知推送', this.systemPush, (v: boolean) => { this.systemPush = v })
      }
      .width('90%').padding(12)
      .backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

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
      .backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F5F5')
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
    Row().width('100%').height(0.5).backgroundColor('#F0F0F0')
  }
}
