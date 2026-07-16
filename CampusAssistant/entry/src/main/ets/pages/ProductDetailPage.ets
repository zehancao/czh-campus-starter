/**
 * 商品详情页 — 谢易霖
 *
 * 严格按 01-database.md + 02-api-doc.md + 商品详情页需求 实现
 *
 * API 清单：
 * - ApiService.getProductDetail(id)        🔓
 * - ApiService.checkFavorite(productId)     🔒
 * - ApiService.addFavorite(productId)       🔒
 * - ApiService.removeFavorite(productId)    🔒
 * - ApiService.createConversation(...)      🔒
 */

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { Product } from '../model/Models';

const CONDITION_LABELS: string[] = ['', '全新', '几乎全新', '有使用痕迹'];
const STATUS_LABELS: string[] = ['', '在售', '已售', '下架'];
const STATUS_COLORS: string[] = ['#FFFFFF', '#10B981', '#6B7280', '#EF4444'];

@Entry
@Component
struct ProductDetailPage {
  @State private product: Product = new Product();
  @State private parsedImages: string[] = [];
  @State private parsedTags: string[] = [];
  @State private isFavorite: boolean = false;
  @State private isLoading: boolean = true;
  @State private isLoggedIn: boolean = false;
  @State private errorMsg: string = '';
  @State private sellerPhoneText: string = '';

  private productId: number = 0;

  aboutToAppear(): void {
    this.resolveId();
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.productId > 0) {
      this.loadDetail();
    } else {
      this.errorMsg = '商品ID无效';
      this.isLoading = false;
    }
  }

  private resolveId(): void {
    let id: number = 0;
    try {
      const ctx = this.getUIContext();
      if (ctx !== null && ctx !== undefined) {
        const routerCtx = ctx.getRouter();
        if (routerCtx !== null && routerCtx !== undefined) {
          const params: Object = routerCtx.getParams();
          if (params !== null && params !== undefined) {
            const p: Record<string, Object> = params as Record<string, Object>;
            let v: Object = p['productId'];
            if (v === null || v === undefined) {
              v = p['id'];
            }
            if (v !== null && v !== undefined) {
              if (typeof v === 'number') {
                id = v as number;
              } else {
                const n: number = Number(v as string);
                if (!isNaN(n)) {
                  id = n;
                }
              }
            }
          }
        }
      }
    } catch (e) {}

    if (id === 0) {
      try {
        const params: Object = router.getParams();
        if (params !== null && params !== undefined) {
          const p: Record<string, Object> = params as Record<string, Object>;
          let v: Object = p['productId'];
          if (v === null || v === undefined) {
            v = p['id'];
          }
          if (v !== null && v !== undefined) {
            if (typeof v === 'number') {
              id = v as number;
            } else {
              const n: number = Number(v as string);
              if (!isNaN(n)) {
                id = n;
              }
            }
          }
        }
      } catch (e) {}
    }

    this.productId = id;
  }

  private async loadDetail(): Promise<void> {
    this.isLoading = true;
    const result = await ApiService.getProductDetail(this.productId);
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      const p: Product = new Product();
      p.id = (obj['id'] as number) ?? 0;
      p.sellerId = (obj['sellerId'] as number) ?? 0;
      p.sellerName = (obj['sellerName'] as string) ?? '';
      p.categoryId = (obj['categoryId'] as number) ?? 0;
      p.categoryName = (obj['categoryName'] as string) ?? '';
      p.title = (obj['title'] as string) ?? '';
      p.description = (obj['description'] as string) ?? '';
      p.price = (obj['price'] as number) ?? 0;
      p.originalPrice = (obj['originalPrice'] as number) ?? 0;
      p.conditionLevel = (obj['conditionLevel'] as number) ?? 1;
      p.status = (obj['status'] as number) ?? 1;
      p.viewCount = (obj['viewCount'] as number) ?? 0;
      p.campusLocation = (obj['campusLocation'] as string) ?? '';
      p.createTime = (obj['createTime'] as string) ?? '';
      this.product = p;

      // 解析 sellerPhone
      const phObj: Object = obj['sellerPhone'];
      if (phObj !== null && phObj !== undefined) {
        this.sellerPhoneText = phObj as string;
      } else {
        this.sellerPhoneText = '';
      }

      // 解析 images (JSON 字符串 → string[])
      const imgObj: Object = obj['images'];
      if (imgObj !== null && imgObj !== undefined) {
        const raw: string = imgObj as string;
        if (raw.length > 0) {
          const c: string = raw.replace('[', '').replace(']', '').replace(new RegExp('"', 'g'), '');
          if (c.length > 0) {
            this.parsedImages = c.split(',');
          }
        }
      }

      // 解析 tags
      const tagObj: Object = obj['tags'];
      if (tagObj !== null && tagObj !== undefined) {
        const raw: string = tagObj as string;
        if (raw.length > 0) {
          const c: string = raw.replace('[', '').replace(']', '').replace(new RegExp('"', 'g'), '');
          if (c.length > 0) {
            this.parsedTags = c.split(',');
          }
        }
      }

      if (this.isLoggedIn && p.id > 0) {
        const fav = await ApiService.checkFavorite(p.id);
        if (fav.code === 200 && fav.data !== undefined) {
          this.isFavorite = fav.data as boolean;
        }
      }
    } else {
      this.errorMsg = result.msg || '加载失败';
    }
    this.isLoading = false;
  }

  private async toggleFavorite(): Promise<void> {
    if (!this.isLoggedIn) {
      AlertDialog.show({ message: '请先登录', confirm: { value: '好的', action: () => {} } });
      return;
    }
    if (this.isFavorite) {
      const r = await ApiService.removeFavorite(this.product.id);
      if (r.code === 200) {
        this.isFavorite = false;
        promptAction.showToast({ message: '已取消收藏' });
      }
    } else {
      const r = await ApiService.addFavorite(this.product.id);
      if (r.code === 200) {
        this.isFavorite = true;
        promptAction.showToast({ message: '已收藏' });
      }
    }
  }

  private contactSeller(): void {
    if (!this.isLoggedIn) {
      AlertDialog.show({ message: '请先登录后联系卖家', confirm: { value: '好的', action: () => {} } });
      return;
    }
    if (this.product.sellerId === 0) {
      AlertDialog.show({ message: '卖家信息异常', confirm: { value: '好的', action: () => {} } });
      return;
    }
    const store: AppStore = AppStore.getInstance();
    if (store.userInfo.id === this.product.sellerId) {
      AlertDialog.show({ message: '这是您自己的商品', confirm: { value: '好的', action: () => {} } });
      return;
    }
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        'otherUserId': this.product.sellerId.toString(),
        'otherUserName': this.product.sellerName,
        'productId': this.product.id.toString()
      } as Record<string, string>
    });
  }

  private reportProduct(): void {
    if (!this.isLoggedIn) {
      AlertDialog.show({ message: '请先登录', confirm: { value: '好的', action: () => {} } });
      return;
    }
    const store: AppStore = AppStore.getInstance();
    if (store.userInfo.id === this.product.sellerId) {
      AlertDialog.show({ message: '不能投诉自己的商品', confirm: { value: '好的', action: () => {} } });
      return;
    }
    router.pushUrl({
      url: 'pages/MyComplaintsPage',
      params: {
        'defendantId': this.product.sellerId.toString(),
        'productId': this.product.id.toString(),
        'defendantName': this.product.sellerName
      } as Record<string, string>
    });
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().color('#FF6B35').width(48).height(48)
          Text('加载中…').fontSize(14).fontColor('#9CA3AF').margin({ top: 12 })
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMsg.length > 0) {
        Column() {
          Text('😕').fontSize(48)
          Text(this.errorMsg).fontSize(16).fontColor('#6B7280').margin({ top: 12 })
          Button('重试')
            .type(ButtonType.Capsule).backgroundColor('#FF6B35').fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => {
              this.errorMsg = '';
              this.isLoading = true;
              this.resolveId();
              if (this.productId > 0) {
                this.loadDetail();
              } else {
                this.errorMsg = '商品ID无效';
                this.isLoading = false;
              }
            })
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // ══════ 图片轮播 ══════
            if (this.parsedImages.length > 0) {
              Swiper() {
                ForEach(this.parsedImages, (img: string) => {
                  Image(ApiService.baseUrl + img)
                    .width('100%')
                    .height(360)
                    .objectFit(ImageFit.Cover)
                }, (img: string) => img)
              }
              .width('100%')
              .height(360)
              .autoPlay(false)
              .indicator(true)
              .loop(false)
            } else {
              Column() {
                Text('📷').fontSize(64)
                Text('暂无图片').fontSize(14).fontColor('#9CA3AF').margin({ top: 8 })
              }
              .width('100%').height(360)
              .backgroundColor('#F3F4F6')
              .justifyContent(FlexAlign.Center)
            }

            // ══════ 基本信息 ══════
            Column() {
              Row() {
                Text(this.product.title)
                  .fontSize(20).fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                Blank()
              }
              .width('100%')

              Row() {
                Text('¥' + this.product.price.toFixed(2))
                  .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FF6B35')
                if (this.product.originalPrice > 0) {
                  Text('¥' + this.product.originalPrice.toFixed(2))
                    .fontSize(14).fontColor('#9CA3AF')
                    .decoration({ type: TextDecorationType.LineThrough })
                    .margin({ left: 8 })
                }
                Blank()
              }
              .width('100%').margin({ top: 6 })

              Row() {
                Text(STATUS_LABELS[Math.max(0, Math.min(this.product.status, 3))])
                  .fontSize(12).fontColor('#FFFFFF')
                  .backgroundColor(STATUS_COLORS[Math.max(0, Math.min(this.product.status, 3))])
                  .borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 })
                Text(CONDITION_LABELS[Math.max(0, Math.min(this.product.conditionLevel, 3))])
                  .fontSize(12).fontColor('#FF6B35')
                  .backgroundColor('#FFF3ED')
                  .borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .margin({ left: 8 })
                if (this.product.categoryName.length > 0) {
                  Text(this.product.categoryName)
                    .fontSize(12).fontColor('#6B7280')
                    .backgroundColor('#F3F4F6')
                    .borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .margin({ left: 8 })
                }
                Blank()
              }
              .width('100%').margin({ top: 8 })
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF')

            Divider().height(8).color('#F3F4F6').width('100%')

            // ══════ 卖家信息 + 电话 ══════
            Row() {
              Column() {
                Text(this.product.sellerName).fontSize(16).fontWeight(FontWeight.Medium)
                Text('卖家').fontSize(12).fontColor('#9CA3AF').margin({ top: 2 })
                if (this.sellerPhoneText.length > 0) {
                  Text('📞 ' + this.sellerPhoneText)
                    .fontSize(13).fontColor('#FF6B35')
                    .margin({ top: 4 })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ right: 20 })

              if (this.product.campusLocation.length > 0) {
                Divider().vertical(true).height(30).color('#E5E7EB')
                Column() {
                  Text('交易地点').fontSize(12).fontColor('#9CA3AF')
                  Text(this.product.campusLocation).fontSize(14).fontColor('#374151').margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Center).margin({ left: 16 })
              }
              Blank()
              Column() {
                Text('浏览量').fontSize(12).fontColor('#9CA3AF')
                Text(this.product.viewCount.toString())
                  .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#374151').margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF')

            Divider().height(8).color('#F3F4F6').width('100%')

            // ══════ 商品描述 ══════
            Column() {
              Row() {
                Text('商品描述').fontSize(16).fontWeight(FontWeight.Bold)
                Blank()
              }
              .width('100%')
              Text(this.product.description.length > 0 ? this.product.description : '暂无描述')
                .fontSize(14).fontColor('#4B5563').width('100%').margin({ top: 8 })
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF')

            Divider().height(8).color('#F3F4F6').width('100%')

            // ══════ 标签 ══════
            if (this.parsedTags.length > 0) {
              Column() {
                Row() {
                  Text('标签').fontSize(16).fontWeight(FontWeight.Bold)
                  Blank()
                }
                .width('100%').margin({ bottom: 8 })
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.parsedTags, (tag: string) => {
                    Text(tag)
                      .fontSize(12).fontColor('#FF6B35')
                      .backgroundColor('#FFF3ED')
                      .border({ width: 1, color: '#FF6B35' })
                      .borderRadius(12)
                      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                      .margin({ right: 8, bottom: 4 })
                  }, (tag: string) => tag)
                  Blank()
                }
                .width('100%')
              }
              .width('100%').padding(16).backgroundColor('#FFFFFF')
              Divider().height(8).color('#F3F4F6').width('100%')
            }

            // ══════ 时间信息 ══════
            Column() {
              Row() {
                Text('发布时间').fontSize(14).fontColor('#9CA3AF').width(80)
                Text(this.formatTime(this.product.createTime)).fontSize(14).fontColor('#374151')
                Blank()
              }
              .width('100%').padding({ top: 4, bottom: 4 })
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF')

            Blank().height(16)
          }
        }
        .layoutWeight(1).width('100%')

        Row() {
          Column() {
            Text(this.isFavorite ? '❤️' : '🤍').fontSize(22)
          }
          .width(48).height(48)
          .backgroundColor(this.isFavorite ? '#FFF3ED' : '#F3F4F6')
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.toggleFavorite() })

          Column() {
            Text('⚠️').fontSize(20)
          }
          .width(48).height(48)
          .backgroundColor('#F3F4F6')
          .borderRadius(24)
          .margin({ left: 10 })
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.reportProduct() })

          Blank()

          Button('联系卖家')
            .type(ButtonType.Capsule)
            .backgroundColor('#FF6B35')
            .fontColor('#FFFFFF')
            .borderRadius(22)
            .height(44)
            .padding({ left: 28, right: 28 })
            .onClick(() => { this.contactSeller() })
        }
        .width('100%').height(64)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 4, color: '#0000001A', offsetY: -2 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F9FAFB')
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
