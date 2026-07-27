import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService, ApiResult } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { FavoriteItem, StudyShareItem } from '../model/Models';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const STATUS_LABELS: string[] = ['', '在售', '已售', '下架'];
const STATUS_COLORS: string[] = [Theme.bgCard, Theme.success, Theme.textSecondary, Theme.danger];

@Component
struct FavoriteCard {
  item: FavoriteItem = new FavoriteItem();
  onTap?: () => void;
  onRemove?: () => void;

  build() {
    Row() {
      if (this.item.productImages.length > 0) {
        Image(ApiService.baseUrl + this.item.productImages[0])
          .width(96)
          .height(96)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('\uD83D\uDCF7')
            .fontSize(34)
        }
        .width(96)
        .height(96)
        .backgroundColor(Theme.bgPage)
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Row() {
          Text(this.item.productTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Blank()
          Text(`\u00A5${this.item.productPrice.toFixed(2)}`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.secondary)
        }
        .width('100%')

        Text(this.item.sellerName)
          .fontSize(13)
          .fontColor(Theme.textSecondary)
          .width('100%')
          .margin({ top: 6 })

        Row() {
          Text(STATUS_LABELS[Math.max(0, Math.min(this.item.productStatus, 3))])
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(STATUS_COLORS[Math.max(0, Math.min(this.item.productStatus, 3))])
            .borderRadius(4)
            .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          Blank()

          Button('取消收藏')
            .type(ButtonType.Capsule)
            .fontSize(11)
            .fontColor(Theme.danger)
            .backgroundColor(Theme.dangerLight)
            .height(28)
            .padding({ left: 10, right: 10 })
            .onClick(() => {
              if (this.onRemove !== undefined) {
                this.onRemove();
              }
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => {
      if (this.onTap !== undefined) {
        this.onTap();
      }
    })
  }
}

@Component
struct StudyShareFavoriteCard {
  item: StudyShareItem = new StudyShareItem();
  onTap?: () => void;

  build() {
    Row() {
      if (this.item.coverImage.length > 0) {
        Image(ApiService.baseUrl + this.item.coverImage)
          .width(72)
          .height(72)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('\uD83D\uDCC4')
            .fontSize(34)
        }
        .width(72)
        .height(72)
        .backgroundColor(Theme.bgPage)
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Text(this.item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(`${this.item.courseName} \u00B7 ${this.item.category}`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width('100%')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(`\u2764 ${this.item.likeCount}`)
            .fontSize(12)
            .fontColor(Theme.textTertiary)
          Text(`\u2B07 ${this.item.downloadCount}`)
            .fontSize(12)
            .fontColor(Theme.textTertiary)
            .margin({ left: 12 })
          Blank()
          Text('资料')
            .fontSize(11)
            .fontColor(Theme.primary)
            .backgroundColor(Theme.primaryLight)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
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
    .margin({ bottom: 12 })
    .onClick(() => {
      if (this.onTap !== undefined) {
        this.onTap();
      }
    })
  }
}

@Entry
@Component
struct MyFavoritesPage {
  @State private favorites: FavoriteItem[] = [];
  @State private studyFavorites: StudyShareItem[] = [];
  @State private isLoading: boolean = true;
  @State private isLoggedIn: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.loadData();
    } else {
      this.isLoading = false;
    }
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    const favResult = await ApiService.getMyFavorites();
    if (favResult.code === 200 && favResult.data !== undefined) {
      this.favorites = ApiService.parseFavoriteList(favResult.data);
    }
    const studyResult = await ApiService.getMyStudyShareFavorites();
    if (studyResult.code === 200 && studyResult.data !== undefined) {
      this.studyFavorites = ApiService.parseStudyShareList(studyResult.data);
    }
    this.isLoading = false;
  }

  private async removeFavorite(item: FavoriteItem): Promise<void> {
    const result = await ApiService.removeFavorite(item.productId);
    if (result.code === 200) {
      const idx: number = this.favorites.findIndex(i => i.productId === item.productId);
      if (idx >= 0) {
        this.favorites.splice(idx, 1);
        this.favorites = this.favorites.slice();
      }
      this.getUIContext().getPromptAction().showToast({ message: '已取消收藏', duration: 1500 });
    } else {
      AlertDialog.show({
        message: result.msg || '操作失败',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private goToProductDetail(item: FavoriteItem): void {
    router.pushUrl({
      url: 'pages/ProductDetailPage',
      params: { 'productId': item.productId } as Record<string, Object>
    });
  }

  private goToStudyDetail(item: StudyShareItem): void {
    router.pushUrl({
      url: 'pages/StudyShareDetailPage',
      params: { 'id': `${item.id}` } as Record<string, string>
    });
  }

  private totalCount(): number {
    return this.favorites.length + this.studyFavorites.length;
  }

  build() {
    Column() {
      NavHeader({ title: '我的收藏' }) {
        if (this.totalCount() > 0) {
          Text(`${this.totalCount()}`)
            .fontSize(13).fontColor(Theme.textTertiary)
            .backgroundColor(Theme.bgPage).borderRadius(10)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
      }

      if (!this.isLoggedIn) {
        Column() {
          Text('\uD83D\uDD12')
            .fontSize(56)
          Text('请先登录查看收藏')
            .fontSize(16)
            .fontColor(Theme.textSecondary)
            .margin({ top: 12 })
          Button('去登录')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.secondary)
            .fontColor('#FFFFFF')
            .margin({ top: 24 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' });
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      } else if (this.isLoading) {
        Column() {
          LoadingProgress()
            .color(Theme.secondary)
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      } else if (this.totalCount() === 0) {
        Column() {
          Text('\uD83E\uDD0D')
            .fontSize(64)
          Text('还没有收藏内容')
            .fontSize(17)
            .fontColor(Theme.textPrimary)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 16 })
          Text('在商品或资料详情页点击\u2764即可收藏')
            .fontSize(13)
            .fontColor(Theme.textTertiary)
            .margin({ top: 6 })
          Button('去逛逛')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.secondary)
            .fontColor('#FFFFFF')
            .margin({ top: 28 })
            .onClick(() => {
              AppStore.getInstance().pendingTab = 1;
              router.pushUrl({ url: 'pages/MainPage' });
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      } else {
        Scroll() {
          Column() {
            Row() {
              Text(`共 ${this.totalCount()} 项收藏`)
                .fontSize(13)
                .fontColor(Theme.textSecondary)
              Blank()
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 8 })

            Column() {
              ForEach(this.favorites, (item: FavoriteItem) => {
                FavoriteCard({
                  item: item,
                  onTap: () => this.goToProductDetail(item),
                  onRemove: () => this.removeFavorite(item)
                })
              }, (item: FavoriteItem) => `product_${item.id}`)

              ForEach(this.studyFavorites, (item: StudyShareItem) => {
                StudyShareFavoriteCard({
                  item: item,
                  onTap: () => this.goToStudyDetail(item)
                })
              }, (item: StudyShareItem) => `study_${item.id}`)
            }
            .width('100%')
            .padding({ left: 12, right: 12, bottom: 20 })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
