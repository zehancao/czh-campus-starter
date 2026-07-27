import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { CarpoolOrder } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const STATUS_TABS: string[] = ['全部', '招募中', '已满', '已出发'];
const STATUS_VALUES: number[] = [-1, 0, 1, 2];
const STATUS_COLORS: Record<string, string> = {
  '0': Theme.success,
  '1': Theme.warning,
  '2': Theme.primary,
  '3': Theme.textDisabled
};
const STATUS_BG: Record<string, string> = {
  '0': '#DCFCE7',
  '1': '#FEF3C7',
  '2': Theme.primaryLight,
  '3': '#F3F4F6'
};
const STATUS_LABELS: Record<string, string> = {
  '0': '招募中',
  '1': '已满',
  '2': '已出发',
  '3': '已取消'
};
const PAGE_SIZE: number = 20;

@Component
struct CarpoolCard {
  private itemData: CarpoolOrder = new CarpoolOrder();
  private onTapCallback?: () => void;
  private onJoinCallback?: () => void;
  private onCancelJoinCallback?: () => void;

  build() {
    Column() {
      Row() {
        Text(this.itemData.publisherName)
          .fontSize(13).fontColor(Theme.textSecondary)
        Text(this.formatTime(this.itemData.createTime))
          .fontSize(11).fontColor(Theme.textTertiary).margin({ left: 8 })
        Blank()
        Text(STATUS_LABELS[`${this.itemData.status}`] ?? '未知')
          .fontSize(10).fontWeight(FontWeight.Medium)
          .fontColor(STATUS_COLORS[`${this.itemData.status}`] ?? Theme.textTertiary)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(10)
          .backgroundColor(STATUS_BG[`${this.itemData.status}`] ?? '#F3F4F6')
      }
      .width('100%')

      Row() {
        Column() {
          Text(this.itemData.departure)
            .fontSize(15).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
          Text('出发')
            .fontSize(11).fontColor(Theme.textTertiary).margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text('→').fontSize(20).fontColor(Theme.primary)
        }
        .justifyContent(FlexAlign.Center)
        .width(40)

        Column() {
          Text(this.itemData.destination)
            .fontSize(15).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
          Text('到达')
            .fontSize(11).fontColor(Theme.textTertiary).margin({ top: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 10 })

      Row() {
        Text(`🕐 ${this.formatTime(this.itemData.departureTime)}`)
          .fontSize(12).fontColor(Theme.textSecondary)
        Text(`👥 ${this.itemData.currentPassengers}/${this.itemData.maxPassengers}人`)
          .fontSize(12).fontColor(Theme.textSecondary).margin({ left: 16 })
      }
      .width('100%')
      .margin({ top: 8 })

      if (this.itemData.remark.length > 0) {
        Text(this.itemData.remark)
          .fontSize(12).fontColor(Theme.textTertiary).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%').margin({ top: 6 })
      }

      if (this.itemData.status === 0 || this.itemData.status === 1) {
        Row() {
          if (this.itemData.joined) {
            Button('已加入-退出')
              .fontSize(12).height(28).type(ButtonType.Normal)
              .backgroundColor('#FEF3C7').fontColor(Theme.warning)
              .borderRadius(14)
              .onClick(() => {
                if (this.onCancelJoinCallback !== undefined) {
                  this.onCancelJoinCallback();
                }
              })
          } else if (this.itemData.currentPassengers < this.itemData.maxPassengers) {
            Button('加入拼车')
              .fontSize(12).height(28).type(ButtonType.Normal)
              .backgroundColor(Theme.primaryLight).fontColor(Theme.primary)
              .borderRadius(14)
              .onClick(() => {
                if (this.onJoinCallback !== undefined) {
                  this.onJoinCallback();
                }
              })
          } else {
            Text('已满员')
              .fontSize(12).fontColor(Theme.textDisabled)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(Theme.cardRadius)
    .margin({ bottom: 10 })
    .shadow(ShadowStyle.sm)
    .onClick(() => {
      if (this.onTapCallback !== undefined) {
        this.onTapCallback();
      }
    })
  }

  private formatTime(timeStr: string): string {
    if (timeStr.length === 0) return '';
    const t: string = timeStr.replace('T', ' ');
    if (t.length > 16) return t.substring(0, 16);
    return t;
  }
}

@Entry
@Component
struct CarpoolPage {
  @State private orders: CarpoolOrder[] = [];
  @State private activeTab: number = 0;
  @State private isLoading: boolean = true;
  @State private currentPage: number = 1;
  @State private hasMore: boolean = true;
  @State private isLoadingMore: boolean = false;
  @State private showMine: boolean = false;
  @State private searchDest: string = '';

  onPageShow(): void {
    if (this.showMine) {
      this.loadMyOrders();
    } else {
      this.refreshList();
    }
  }

  private async refreshList(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 1;
    this.hasMore = true;
    const status: number = STATUS_VALUES[this.activeTab];
    const result = await ApiService.getCarpoolList(this.searchDest, status, 1, PAGE_SIZE);
    if (result.code === 200 && result.data !== undefined) {
      this.orders = ApiService.parseCarpoolOrders(result.data);
      this.hasMore = this.orders.length >= PAGE_SIZE;
    } else {
      this.orders = [];
      this.hasMore = false;
    }
    this.isLoading = false;
  }

  private async loadMore(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) return;
    this.isLoadingMore = true;
    this.currentPage = this.currentPage + 1;
    const status: number = STATUS_VALUES[this.activeTab];
    const result = await ApiService.getCarpoolList(this.searchDest, status, this.currentPage, PAGE_SIZE);
    if (result.code === 200 && result.data !== undefined) {
      const newItems: CarpoolOrder[] = ApiService.parseCarpoolOrders(result.data);
      for (let i = 0; i < newItems.length; i++) {
        this.orders.push(newItems[i]);
      }
      this.hasMore = newItems.length >= PAGE_SIZE;
    } else {
      this.hasMore = false;
    }
    this.isLoadingMore = false;
  }

  private async loadMyOrders(): Promise<void> {
    this.isLoading = true;
    const result = await ApiService.getMyCarpoolOrders();
    if (result.code === 200 && result.data !== undefined) {
      this.orders = ApiService.parseCarpoolOrders(result.data);
    } else {
      this.orders = [];
    }
    this.hasMore = false;
    this.isLoading = false;
  }

  private onTabChange(index: number): void {
    this.activeTab = index;
    this.showMine = false;
    this.refreshList();
  }

  private onToggleMine(): void {
    this.showMine = !this.showMine;
    if (this.showMine) {
      this.loadMyOrders();
    } else {
      this.refreshList();
    }
  }

  private doSearch(): void {
    if (this.showMine) {
      this.showMine = false;
    }
    this.refreshList();
  }

  private goToDetail(item: CarpoolOrder): void {
    router.pushUrl({
      url: 'pages/CarpoolDetailPage',
      params: { 'id': `${item.id}` } as Record<string, string>
    });
  }

  private goToPublish(): void {
    router.pushUrl({ url: 'pages/CarpoolPublishPage' });
  }

  private async joinOrder(item: CarpoolOrder): Promise<void> {
    const result = await ApiService.joinCarpool(item.id);
    if (result.code === 200) {
      if (this.showMine) {
        this.loadMyOrders();
      } else {
        this.refreshList();
      }
    }
  }

  private async cancelJoinOrder(item: CarpoolOrder): Promise<void> {
    const result = await ApiService.cancelJoinCarpool(item.id);
    if (result.code === 200) {
      if (this.showMine) {
        this.loadMyOrders();
      } else {
        this.refreshList();
      }
    }
  }

  build() {
    Column() {
      NavHeader({ title: '拼车' }) {
        Row({ space: 8 }) {
          if (this.showMine) {
            Text('全部').fontSize(13).fontColor(Theme.primary)
              .onClick(() => { this.onToggleMine() })
          } else {
            Text('我的').fontSize(13).fontColor(Theme.textSecondary)
              .onClick(() => { this.onToggleMine() })
          }
          Text('发布').fontSize(13).fontColor(Theme.primary)
            .onClick(() => { this.goToPublish() })
        }
      }

      if (!this.showMine) {
        Row() {
          ForEach(STATUS_TABS, (tab: string, index: number) => {
            Column() {
              Text(tab)
                .fontSize(14)
                .fontColor(this.activeTab === index ? Theme.primary : Theme.textSecondary)
                .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Regular)
              Divider()
                .height(2).width(24)
                .color(this.activeTab === index ? Theme.primary : 'transparent')
                .borderRadius(1).margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 4, bottom: 4 })
            .onClick(() => { this.onTabChange(index) })
          }, (tab: string) => tab)
        }
        .width('100%').backgroundColor('#FFFFFF')

        Row() {
          TextInput({ placeholder: '搜索目的地...', text: this.searchDest })
            .fontSize(13).layoutWeight(1).height(36)
            .borderRadius(18).backgroundColor('#F3F4F6')
            .onChange((value: string) => { this.searchDest = value })
            .onSubmit(() => { this.doSearch() })
          Text('搜索').fontSize(13).fontColor(Theme.primary).margin({ left: 8 })
            .onClick(() => { this.doSearch() })
        }
        .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
      }

      Divider().height(1).color(Theme.border)

      if (this.isLoading) {
        Column() {
          LoadingProgress().color(Theme.primary).width(36).height(36)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          if (this.orders.length > 0) {
            ForEach(this.orders, (item: CarpoolOrder) => {
              ListItem() {
                CarpoolCard({
                  itemData: item,
                  onTapCallback: () => this.goToDetail(item),
                  onJoinCallback: () => this.joinOrder(item),
                  onCancelJoinCallback: () => this.cancelJoinOrder(item)
                })
              }
            }, (item: CarpoolOrder) => `${item.id}`)
          } else {
            ListItem() {
              Column() {
                Text('🚗').fontSize(56)
                Text('暂无拼车信息')
                  .fontSize(15).fontColor(Theme.textSecondary).margin({ top: 8 })
                Text('点击右上角"发布"发起拼车吧')
                  .fontSize(13).fontColor(Theme.textTertiary).margin({ top: 4 })
              }
              .width('100%').alignItems(HorizontalAlign.Center).margin({ top: 40 })
            }
          }

          if (this.hasMore && this.orders.length > 0) {
            ListItem() {
              Row() {
                LoadingProgress().width(20).height(20).color(Theme.primary)
                Text('加载更多...').fontSize(13).fontColor(Theme.textTertiary).margin({ left: 8 })
              }
              .width('100%').justifyContent(FlexAlign.Center).padding({ top: 12, bottom: 12 })
            }
          } else if (!this.hasMore && this.orders.length > 0) {
            ListItem() {
              Text('- 没有更多了 -')
                .fontSize(12).fontColor(Theme.textDisabled)
                .width('100%').textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
            }
          }
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .padding({ left: 12, right: 12, top: 4, bottom: 20 })
        .onReachEnd(() => { this.loadMore() })
      }
    }
    .width('100%').height('100%').backgroundColor(Theme.bgPage)
  }
}
