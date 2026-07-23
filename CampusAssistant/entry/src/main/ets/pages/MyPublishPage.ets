import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService, ApiResult } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { Product } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const STATUS_LABELS: string[] = ['', '在售', '已售', '下架'];
const STATUS_COLORS: string[] = [Theme.bgCard, Theme.success, Theme.textSecondary, Theme.danger];
const CONDITION_LABELS: string[] = ['', '全新', '几乎全新', '轻微使用痕迹', '明显使用痕迹', '成色一般'];

@Component
struct MyProductCard {
  private item: Product = new Product();
  private onTap?: () => void;
  private onStatusChange?: (status: number) => void;
  private onDelete?: () => void;

  build() {
    Row() {
      if (this.item.images.length > 0) {
        Image(ApiService.baseUrl + this.item.images[0])
          .width(96)
          .height(96)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('📦')
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
          Text(this.item.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Blank()
          Text(`¥${this.item.price.toFixed(2)}`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.secondary)
        }
        .width('100%')

        Text(`${CONDITION_LABELS[Math.max(1, Math.min(this.item.conditionLevel, 5))]}`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width('100%')
          .margin({ top: 4 })

        Text(`浏览 ${this.item.viewCount} · ${this.item.createTime}`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width('100%')
          .margin({ top: 2 })

        Row() {
          Text(STATUS_LABELS[Math.max(0, Math.min(this.item.status, 3))])
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(STATUS_COLORS[Math.max(0, Math.min(this.item.status, 3))])
            .borderRadius(4)
            .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          Blank()

          if (this.item.status === 1) {
            Button('下架')
              .type(ButtonType.Capsule)
              .fontSize(11)
              .fontColor(Theme.danger)
              .backgroundColor(Theme.dangerLight)
              .height(28)
              .padding({ left: 10, right: 10 })
              .onClick(() => {
                if (this.onStatusChange !== undefined) {
                  this.onStatusChange(3);
                }
              })
          } else if (this.item.status === 3) {
            Button('上架')
              .type(ButtonType.Capsule)
              .fontSize(11)
              .fontColor(Theme.success)
              .backgroundColor(Theme.successLight)
              .height(28)
              .padding({ left: 10, right: 10 })
              .onClick(() => {
                if (this.onStatusChange !== undefined) {
                  this.onStatusChange(1);
                }
              })
          } else {
            Button('已售')
              .type(ButtonType.Capsule)
              .fontSize(11)
              .fontColor(Theme.textSecondary)
              .backgroundColor(Theme.bgPage)
              .height(28)
              .padding({ left: 10, right: 10 })
              .enabled(false)
          }

          Button('删除')
            .type(ButtonType.Capsule)
            .fontSize(11)
            .fontColor(Theme.danger)
            .backgroundColor(Theme.dangerLight)
            .height(28)
            .padding({ left: 10, right: 10 })
            .margin({ left: 6 })
            .onClick(() => {
              if (this.onDelete !== undefined) {
                this.onDelete();
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

@Entry
@Component
struct MyPublishPage {
  @State private products: Product[] = [];
  @State private isLoading: boolean = true;
  @State private isLoggedIn: boolean = false;
  @State private isRefreshing: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.loadProducts();
    } else {
      this.isLoading = false;
    }
  }

  private async loadProducts(): Promise<void> {
    this.isRefreshing = true;
    const result: ApiResult = await ApiService.getMyProducts();
    if (result.code === 200 && result.data !== undefined) {
      this.products = ApiService.parseProductList(result.data);
    }
    this.isLoading = false;
    this.isRefreshing = false;
  }

  private async changeStatus(product: Product, status: number): Promise<void> {
    const result: ApiResult = await ApiService.updateProductStatus(product.id, status);
    if (result.code === 200) {
      product.status = status;
      this.products = this.products.slice();
      promptAction.showToast({ message: status === 1 ? '已上架' : '已下架', duration: 1500 });
    } else {
      AlertDialog.show({
        message: result.msg || '操作失败',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private async deleteProduct(product: Product): Promise<void> {
    const result: ApiResult = await ApiService.deleteProduct(product.id);
    if (result.code === 200) {
      const idx: number = this.products.findIndex((p: Product) => p.id === product.id);
      if (idx >= 0) {
        this.products.splice(idx, 1);
        this.products = this.products.slice();
      }
      promptAction.showToast({ message: '已删除', duration: 1500 });
    } else {
      AlertDialog.show({
        message: result.msg || '删除失败',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private goToDetail(product: Product): void {
    router.pushUrl({
      url: 'pages/ProductDetailPage',
      params: { 'productId': product.id } as Record<string, Object>
    });
  }

  build() {
    Column() {
      NavHeader({ title: '我的发布' }) {
        if (this.products.length > 0) {
          Text(`${this.products.length}`)
            .fontSize(13).fontColor(Theme.textTertiary)
            .backgroundColor(Theme.bgPage).borderRadius(10)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
      }

      if (!this.isLoggedIn) {
        Column() {
          Text('🔒')
            .fontSize(56)
          Text('请先登录查看发布')
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
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 80 })

      } else if (this.isLoading) {
        Column() {
          LoadingProgress()
            .color(Theme.secondary)
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 80 })

      } else if (this.products.length === 0) {
        Column() {
          Text('📦')
            .fontSize(64)
          Text('还没有发布商品')
            .fontSize(17)
            .fontColor(Theme.textPrimary)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 16 })
          Text('去发布闲置物品赚取零花钱')
            .fontSize(13)
            .fontColor(Theme.textTertiary)
            .margin({ top: 6 })
          Button('去发布')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.secondary)
            .fontColor('#FFFFFF')
            .margin({ top: 28 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/PublishPage' });
            })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 80 })

      } else {
        Scroll() {
          Column() {
            Row() {
              Text(`共 ${this.products.length} 件发布`)
                .fontSize(13)
              .fontColor(Theme.textSecondary)
              Blank()
              if (this.isRefreshing) {
                LoadingProgress()
                  .color(Theme.secondary)
                  .width(14)
                  .height(14)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 8 })

            Column() {
              ForEach(this.products, (item: Product) => {
                MyProductCard({
                  item: item,
                  onTap: () => this.goToDetail(item),
                  onStatusChange: (status: number) => this.changeStatus(item, status),
                  onDelete: () => this.deleteProduct(item)
                })
              }, (item: Product) => item.id.toString())
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
