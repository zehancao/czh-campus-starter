/**
 * 我的收藏页 — 谢易霖
 *
 * 功能：
 * - 展示收藏的商品列表（封面、标题、价格、卖家、状态）
 * - 点击取消收藏按钮移除
 * - 点击进入商品详情
 * - 空状态 / 未登录状态
 *
 * API：
 * - ApiService.getMyFavorites()         🔒
 * - ApiService.removeFavorite(id)       🔒
 * - ApiService.parseFavoriteList(data)  🔒
 *
 * 数据库表 favorites：
 *   id, user_id（登录用户）, product_id, create_time
 */

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { FavoriteItem } from '../model/Models';

/** 状态映射 */
const STATUS_LABELS: string[] = ['', '在售', '已售', '下架'];
const STATUS_COLORS: string[] = ['#FFFFFF', '#10B981', '#6B7280', '#EF4444'];

// ─────────────────────────────────────────────
//  组件：收藏卡片
// ─────────────────────────────────────────────
@Component
struct FavoriteCard {
  private item: FavoriteItem = new FavoriteItem();
  private onTap?: () => void;
  private onRemove?: () => void;

  build() {
    Row() {
      // 封面图
      if (this.item.productImages.length > 0) {
        Image(ApiService.baseUrl + this.item.productImages[0])
          .width(96)
          .height(96)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('📷')
            .fontSize(34)
        }
        .width(96)
        .height(96)
        .backgroundColor('#F3F4F6')
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
      }

      // 右侧信息
      Column() {
        // 标题 + 价格行
        Row() {
          Text(this.item.productTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Blank()
          Text(`¥${this.item.productPrice.toFixed(2)}`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B35')
        }
        .width('100%')

        // 卖家
        Text(this.item.sellerName)
          .fontSize(13)
          .fontColor('#6B7280')
          .width('100%')
          .margin({ top: 6 })

        // 底部：状态 + 取消收藏按钮
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
            .fontColor('#EF4444')
            .backgroundColor('#FEF2F2')
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

// ─────────────────────────────────────────────
//  页面
// ─────────────────────────────────────────────
@Entry
@Component
struct MyFavoritesPage {
  @State private favorites: FavoriteItem[] = [];
  @State private isLoading: boolean = true;
  @State private isLoggedIn: boolean = false;
  @State private isRefreshing: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.loadFavorites();
    } else {
      this.isLoading = false;
    }
  }

  // ── 加载收藏列表 ──
  private async loadFavorites(): Promise<void> {
    this.isRefreshing = true;
    const result = await ApiService.getMyFavorites();
    if (result.code === 200 && result.data !== undefined) {
      this.favorites = ApiService.parseFavoriteList(result.data);
    }
    this.isLoading = false;
    this.isRefreshing = false;
  }

  // ── 取消收藏 ──
  private async removeFavorite(item: FavoriteItem): Promise<void> {
    const result = await ApiService.removeFavorite(item.productId);
    if (result.code === 200) {
      const idx: number = this.favorites.findIndex(i => i.productId === item.productId);
      if (idx >= 0) {
        this.favorites.splice(idx, 1);
        this.favorites = this.favorites.slice();
      }
      promptAction.showToast({ message: '已取消收藏', duration: 1500 });
    } else {
      AlertDialog.show({
        message: result.msg || '操作失败',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  // ── 跳转商品详情 ──
  private goToDetail(item: FavoriteItem): void {
    router.pushUrl({
      url: 'pages/MainPage',
      params: { 'productId': item.productId } as Record<string, Object>
    });
  }

  // ── 下拉刷新 ──
  private onRefresh(): void {
    if (!this.isRefreshing) {
      this.loadFavorites();
    }
  }

  build() {
    Column() {
      // ═══════════════ 顶部导航栏 ═══════════════
      Row() {
        Text('‹ 返回')
          .fontSize(16)
          .fontColor('#6B7280')
          .onClick(() => { router.back() })

        Blank()

        Text('我的收藏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)

        Blank()

        if (this.favorites.length > 0) {
          Text(`${this.favorites.length}`)
            .fontSize(13)
            .fontColor('#9CA3AF')
            .backgroundColor('#F3F4F6')
            .borderRadius(10)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        } else {
          Blank().width(40)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // ═══════════════ 内容区 ═══════════════
      if (!this.isLoggedIn) {
        // ── 未登录 ──
        Column() {
          Text('🔒')
            .fontSize(56)
          Text('请先登录查看收藏')
            .fontSize(16)
            .fontColor('#6B7280')
            .margin({ top: 12 })
          Button('去登录')
            .type(ButtonType.Capsule)
            .backgroundColor('#FF6B35')
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
        // ── 加载中 ──
        Column() {
          LoadingProgress()
            .color('#FF6B35')
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      } else if (this.favorites.length === 0) {
        // ── 空状态 ──
        Column() {
          Text('🤍')
            .fontSize(64)
          Text('还没有收藏商品')
            .fontSize(17)
            .fontColor('#374151')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 16 })
          Text('在商品详情页点击❤即可收藏')
            .fontSize(13)
            .fontColor('#9CA3AF')
            .margin({ top: 6 })
          Button('去交易')
            .type(ButtonType.Capsule)
            .backgroundColor('#FF6B35')
            .fontColor('#FFFFFF')
            .margin({ top: 28 })
            .onClick(() => {
              router.back()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      } else {
        // ── 收藏列表（核心修改：移除layoutWeight(1)）
        Scroll() {
          Column() {
            // 统计条
            Row() {
              Text(`共 ${this.favorites.length} 件收藏`)
                .fontSize(13)
                .fontColor('#6B7280')
              Blank()
              if (this.isRefreshing) {
                LoadingProgress()
                  .color('#FF6B35')
                  .width(14)
                  .height(14)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 8 })

            // 卡片列表
            Column() {
              ForEach(this.favorites, (item: FavoriteItem) => {
                FavoriteCard({
                  item: item,
                  onTap: () => this.goToDetail(item),
                  onRemove: () => this.removeFavorite(item)
                })
              }, (item: FavoriteItem) => item.id.toString())
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
          }
          .width('100%')
        }
        .width('100%')
        .onReachStart(() => { this.onRefresh() })
      }
    }
    .width('100%')
    .backgroundColor('#F3F4F6')
  }
}
