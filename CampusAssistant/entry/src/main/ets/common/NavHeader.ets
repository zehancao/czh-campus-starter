import { Theme } from './Theme';
import { router } from '@kit.ArkUI';

@Component
export struct NavHeader {
  @Prop title: string = '';
  @BuilderParam rightSlot: () => void = this.defaultSlot;

  @Builder
  defaultSlot(): void {
  }

  build() {
    Row() {
      Image($r('app.media.ic_back'))
        .width(Theme.navBackSize)
        .height(Theme.navBackSize)
        .onClick(() => {
          router.back();
        })
        .padding(4)

      Text(this.title)
        .fontSize(Theme.navTitleSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ left: -32 })

      if (this.rightSlot !== undefined) {
        Row() {
          this.rightSlot();
        }
        .width(32)
        .justifyContent(FlexAlign.End)
      } else {
        Blank().width(32)
      }
    }
    .width('100%')
    .height(Theme.navHeight)
    .padding({ left: 12, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Theme.bgCard)
    .border({ width: { bottom: 0.5 }, color: Theme.border })
  }
}
