import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

class BrowseItem {
  id: number = 0;
  productId: number = 0;
  title: string = '';
  price: number = 0;
  images: string[] = [];
  sellerName: string = '';
  browseTime: string = '';
  status: number = 1;
  conditionLevel: number = 1;
  categoryName: string = '';
}

const STATUS_LABELS: string[] = ['', '在售', '已售', '下架'];
const STATUS_COLORS: string[] = [Theme.bgCard, Theme.success, Theme.textSecondary, Theme.danger];
const CONDITION_LABELS: string[] = ['', '全新', '几乎全新', '轻微使用', '明显磨损'];

function parseImageList(raw: Object): string[] {
  if (raw === null || raw === undefined) return [];
  const s: string = raw as string;
  if (s.length === 0) return [];
  const cleaned: string = s.replace(/[[\]"]/g, '');
  return cleaned.length > 0 ? cleaned.split(',') : [];
}

function fmtTime(t: string): string {
  if (t.length === 0) return '';
  try {
    const d: Date = new Date(t);
    const n: Date = new Date();
    const diff: number = n.getTime() - d.getTime();
    const min: number = Math.floor(diff / 60000);
    if (min < 1) return '刚刚';
    if (min < 60) return `${min}分钟前`;
    const hour: number = Math.floor(diff / 3600000);
    if (hour < 24) return `${hour}小时前`;
    const day: number = Math.floor(diff / 86400000);
    if (day < 7) return `${day}天前`;
    return `${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  } catch (_) {
    return t;
  }
}

@Component
struct HistoryCard {
  private item: BrowseItem = new BrowseItem();
  private onTap?: () => void;

  build() {
    Row() {
      if (this.item.images.length > 0) {
        Image(ApiService.baseUrl + this.item.images[0])
          .width(96).height(96).borderRadius(10).objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('📷').fontSize(34)
        }
        .width(96).height(96)
        .backgroundColor(Theme.bgPage).borderRadius(10)
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Text(this.item.title)
          .fontSize(15).fontWeight(FontWeight.Medium)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(`¥${this.item.price.toFixed(2)}`)
            .fontSize(17).fontWeight(FontWeight.Bold).fontColor(Theme.secondary)
          Blank()
          if (this.item.conditionLevel > 0 && this.item.conditionLevel < CONDITION_LABELS.length) {
            Text(CONDITION_LABELS[this.item.conditionLevel])
              .fontSize(11).fontColor(Theme.textTertiary)
              .backgroundColor(Theme.bgPage).borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
        }
        .width('100%').margin({ top: 4 })

        Text(this.item.sellerName)
          .fontSize(13).fontColor(Theme.textSecondary)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%').margin({ top: 4 })

        Row() {
          Text(STATUS_LABELS[Math.max(0, Math.min(this.item.status, 3))])
            .fontSize(11).fontColor('#FFFFFF')
            .backgroundColor(STATUS_COLORS[Math.max(0, Math.min(this.item.status, 3))])
            .borderRadius(4).padding({ left: 7, right: 7, top: 2, bottom: 2 })
          Blank()
          Text(fmtTime(this.item.browseTime))
            .fontSize(11).fontColor(Theme.textTertiary)
        }
        .width('100%').margin({ top: 6 })
      }
      .layoutWeight(1).margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').padding(12)
    .backgroundColor('#FFFFFF').borderRadius(12).margin({ bottom: 12 })
    .onClick(() => {
      if (this.onTap !== undefined) this.onTap();
    })
  }
}

@Entry
@Component
struct MyHistoryPage {
  @State private historyList: BrowseItem[] = [];
  @State private isLoading: boolean = true;
  @State private isLoggedIn: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.loadHistory();
    } else {
      this.isLoading = false;
    }
  }

  private async loadHistory(): Promise<void> {
    const result = await ApiService.getMyBrowseHistory();
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const list: BrowseItem[] = [];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        const item: BrowseItem = new BrowseItem();
        item.id = (obj['id'] as number) ?? 0;
        item.productId = (obj['productId'] as number) ?? 0;
        item.title = (obj['title'] as string) ?? '';
        item.price = (obj['price'] as number) ?? 0;
        item.images = parseImageList(obj['images']);
        item.sellerName = (obj['sellerName'] as string) ?? '';
        item.browseTime = (obj['browseTime'] as string) ?? '';
        item.status = (obj['status'] as number) ?? 1;
        item.conditionLevel = (obj['conditionLevel'] as number) ?? 1;
        item.categoryName = (obj['categoryName'] as string) ?? '';
        list.push(item);
      }
      this.historyList = list;
    }
    this.isLoading = false;
  }

  private async clearHistory(): Promise<void> {
    AlertDialog.show({
      title: '清空浏览记录',
      message: '确定要清空所有浏览记录吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      confirm: {
        value: '清空',
        fontColor: Theme.danger,
        action: async () => {
          const result = await ApiService.clearBrowseHistory();
          if (result.code === 200) {
            this.historyList = [];
            promptAction.showToast({ message: '浏览记录已清空', duration: 1500 });
          } else {
            promptAction.showToast({ message: result.msg || '操作失败', duration: 1500 });
          }
        }
      }
    })
  }

  private goToDetail(item: BrowseItem): void {
    router.pushUrl({
      url: 'pages/MainPage',
      params: { 'productId': item.productId } as Record<string, Object>
    });
  }

  build() {
    Column() {
      NavHeader({ title: '浏览历史' }) {
        if (this.historyList.length > 0) {
          Text('清空').fontSize(14).fontColor(Theme.danger).onClick(() => { this.clearHistory() })
        }
      }

      if (!this.isLoggedIn) {
        Column() {
          Text('🔒').fontSize(56)
          Text('请先登录查看浏览记录')
            .fontSize(16).fontColor(Theme.textSecondary).margin({ top: 12 })
          Button('去登录')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.secondary).fontColor('#FFFFFF')
            .margin({ top: 24 })
            .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

      } else if (this.isLoading) {
        Column() {
          LoadingProgress().color(Theme.secondary).width(40).height(40)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

      } else if (this.historyList.length === 0) {
        Column() {
          Text('🕐').fontSize(64)
          Text('暂无浏览记录')
            .fontSize(17).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
            .margin({ top: 16 })
          Text('去看看有什么好商品吧')
            .fontSize(13).fontColor(Theme.textTertiary).margin({ top: 6 })
          Button('去逛逛')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.secondary).fontColor('#FFFFFF')
            .margin({ top: 28 })
            .onClick(() => { router.pushUrl({ url: 'pages/MainPage', params: { 'tab': 1 } as Record<string, Object> }) })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

      } else {
        Scroll() {
          Column() {
            Row() {
              Text(`共 ${this.historyList.length} 条记录`)
                .fontSize(13).fontColor(Theme.textSecondary)
              Blank()
            }
            .width('100%').padding({ left: 16, right: 16, bottom: 8 })

            Column() {
              ForEach(this.historyList, (item: BrowseItem) => {
                HistoryCard({
                  item: item,
                  onTap: () => this.goToDetail(item)
                })
              }, (item: BrowseItem) => item.id.toString())
            }
            .width('100%').padding({ left: 12, right: 12 })
          }
          .width('100%')
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
