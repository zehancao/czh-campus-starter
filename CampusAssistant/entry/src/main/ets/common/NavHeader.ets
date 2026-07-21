import { Theme } from './Theme';

@Component
export struct NavHeader {
  @Prop title: string = '';
  @BuilderParam rightSlot: () => void = this.defaultSlot;

  @Builder
  defaultSlot(): void {
  }

  build() {
    Row() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(Theme.navBackSize)
          .height(Theme.navBackSize)
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.getUIContext().getRouter().back();
      })

      Text(this.title)
        .fontSize(Theme.navTitleSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      if (this.rightSlot !== undefined) {
        Row() {
          this.rightSlot();
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Center)
      } else {
        Blank().width(44)
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
