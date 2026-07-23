import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { LostFoundItem } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const TYPE_TABS: string[] = ['全部', '寻物', '招领'];
const STATUS_LABELS: string[] = ['进行中', '已找到'];

@Component
struct LFListCard {
  private itemData: LostFoundItem = new LostFoundItem();
  private onTapCallback?: () => void;

  build() {
    Row() {
      Column() {
        Text(this.itemData.type === 1 ? '🔍' : '📢')
          .fontSize(28)
        Text(this.itemData.type === 1 ? '寻物' : '招领')
          .fontSize(11).fontColor(Theme.secondary).margin({ top: 2 })
      }
      .width(60).height(60)
        .backgroundColor(Theme.secondaryLight)
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(this.itemData.title)
            .fontSize(15).fontWeight(FontWeight.Medium)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(STATUS_LABELS[Math.max(0, Math.min(this.itemData.status - 1, 1))])
            .fontSize(11)
              .fontColor(this.itemData.status === 1 ? Theme.warning : Theme.success)
              .backgroundColor(this.itemData.status === 1 ? Theme.warningLight : Theme.successLight)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
        .width('100%')

        Text(this.itemData.description)
          .fontSize(13).fontColor(Theme.textSecondary)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })

        Row() {
          if (this.itemData.category.length > 0) {
            Text(this.itemData.category)
              .fontSize(11).fontColor(Theme.textTertiary).backgroundColor(Theme.bgPage)
              .borderRadius(4).padding({ left: 6, right: 6, top: 1, bottom: 1 })
          }
          if (this.itemData.locationDesc.length > 0) {
            Text(this.itemData.locationDesc)
              .fontSize(11).fontColor(Theme.textTertiary).backgroundColor(Theme.bgPage)
              .borderRadius(4).padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .margin({ left: 6 })
          }
          Blank()
          Text(this.itemData.userName)
            .fontSize(11).fontColor(Theme.textTertiary)
          Text(' | ')
            .fontSize(11).fontColor(Theme.textDisabled)
          Text(this.formatTime(this.itemData.createTime))
            .fontSize(11).fontColor(Theme.textTertiary)
        }
        .width('100%')
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .shadow(ShadowStyle.sm)
    .onClick(() => {
      if (this.onTapCallback !== undefined) {
        this.onTapCallback();
      }
    })
  }

  private formatTime(timeStr: string): string {
    if (timeStr.length === 0) {
      return '';
    }
    const t: string = timeStr.replace('T', ' ');
    if (t.length > 16) {
      return t.substring(0, 16);
    }
    return t;
  }
}

@Entry
@Component
struct LostFoundListPage {
  @State private items: LostFoundItem[] = [];
  @State private activeTab: number = 0;
  @State private keywordValue: string = '';
  @State private isLoading: boolean = true;

  onPageShow(): void {
    this.loadList();
  }

  private async loadList(): Promise<void> {
    this.isLoading = true;
    let typeVal: number = 0;
    if (this.activeTab === 1) {
      typeVal = 1;
    }
    if (this.activeTab === 2) {
      typeVal = 2;
    }
    try {
      const list: LostFoundItem[] = await ApiService.getLostFoundList(typeVal, this.keywordValue, 1);
      this.items = list;
    } catch (err) {
      console.error("加载列表异常", JSON.stringify(err));
      this.items = [];
    } finally {
      this.isLoading = false;
    }
  }

  private onTabChange(index: number): void {
    this.activeTab = index;
    this.loadList();
  }

  private goToDetail(item: LostFoundItem): void {
    try {
      router.pushUrl({
        url: 'pages/LostFoundDetailPage',
        params: { 'id': item.id.toString() } as Record<string, string>
      });
    } catch (e) {
      console.error("跳转详情页失败", e);
    }
  }

  private goToPublish(): void {
    try {
      router.pushUrl({ url: 'pages/LostFoundPublishPage' });
    } catch (e) {
      console.error("跳转发布页失败", e);
    }
  }

  build() {
    Column() {
      NavHeader({ title: '失物招领' }) {
        Text('发布').fontSize(14).fontColor(Theme.secondary).onClick(() => { this.goToPublish() })
      }

      Row() {
        TextInput({ placeholder: '搜索失物或招领…', text: this.keywordValue })
          .width('85%')
          .height(36)
          .fontSize(14)
          .backgroundColor(Theme.bgInput)
          .borderRadius(18)
          .padding({ left: 16 })
          .onChange((val: string) => { this.keywordValue = val })
          .onSubmit(() => { this.loadList() })
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Row() {
        ForEach(TYPE_TABS, (tab: string, index: number) => {
          Column() {
            Text(tab)
              .fontSize(15)
              .fontColor(this.activeTab === index ? Theme.secondary : Theme.textSecondary)
              .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Regular)
            Divider()
              .height(2)
              .width(24)
              .color(this.activeTab === index ? Theme.secondary : 'transparent')
              .borderRadius(1)
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 4, bottom: 4 })
          .onClick(() => { this.onTabChange(index) })
        }, (tab: string) => tab)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')

      Divider().height(1).color(Theme.border)

      Scroll() {
        Column() {
          Row() {
            Text('共 ' + this.items.length + ' 条')
              .fontSize(12).fontColor(Theme.textTertiary)
            Blank()
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })

          if (this.items.length > 0) {
            ForEach(this.items, (item: LostFoundItem) => {
              LFListCard({
                itemData: item,
                onTapCallback: () => this.goToDetail(item)
              })
            }, (item: LostFoundItem) => item.id.toString())
          } else {
            Column() {
              Text('🕊️').fontSize(56)
              Text(this.keywordValue.length > 0 ? '没有找到相关结果' : '暂无失物招领信息')
                .fontSize(15).fontColor(Theme.textSecondary).margin({ top: 8 })
              if (this.keywordValue.length > 0) {
                Text('试试其他关键词')
                  .fontSize(13).fontColor(Theme.textTertiary).margin({ top: 4 })
              } else {
                Text('点击右上角"发布"发布失物或招领信息')
                  .fontSize(13).fontColor(Theme.textTertiary).margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ top: 40 })
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 4, bottom: 20 })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}