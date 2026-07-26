import { NavHeader } from '../common/NavHeader';
import { Theme } from '../common/Theme';

@Entry
@Component
struct StudySharePage {
  build() {
    Column() {
      NavHeader({ title: '学习资料' })

      Column() {
        Text('📚')
          .fontSize(48)
          .margin({ bottom: 16 })

        Text('学习资料共享')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.textPrimary)
          .margin({ bottom: 8 })

        Text('分享课程资料，互帮互助')
          .fontSize(14)
          .fontColor(Theme.textTertiary)

        Text('功能开发中，敬请期待...')
          .fontSize(13)
          .fontColor(Theme.textTertiary)
          .margin({ top: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
