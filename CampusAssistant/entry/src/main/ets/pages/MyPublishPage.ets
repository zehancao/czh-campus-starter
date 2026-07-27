import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService, ApiResult } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { Product, ClubActivityItem, CarpoolOrder, ConfessionPost, StudyShareItem } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const STATUS_LABELS: string[] = ['', '在售', '已售', '下架'];
const STATUS_COLORS: string[] = [Theme.bgCard, Theme.success, Theme.textSecondary, Theme.danger];
const CONDITION_LABELS: string[] = ['', '全新', '几乎全新', '轻微使用痕迹', '明显使用痕迹', '成色一般'];
const ACTIVITY_STATUS: string[] = ['', '报名中', '已满', '已结束'];
const ACTIVITY_STATUS_COLORS: string[] = [Theme.bgCard, Theme.success, Theme.warning, Theme.textTertiary];
const CARPOOL_STATUS: string[] = ['', '招募中', '已满员', '已取消'];
const CARPOOL_STATUS_COLORS: string[] = [Theme.bgCard, Theme.success, Theme.warning, Theme.danger];

@Component
struct MyProductCard {
  item: Product = new Product();
  onTap?: () => void;
  onStatusChange?: (status: number) => void;
  onDelete?: () => void;

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
          Text('\uD83D\uDCE6')
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
          Text(`\u00A5${this.item.price.toFixed(2)}`)
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

        Text(`浏览 ${this.item.viewCount} \u00B7 ${this.item.createTime}`)
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

@Component
struct MyActivityCard {
  item: ClubActivityItem = new ClubActivityItem();
  onTap?: () => void;
  onDelete?: () => void;

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
          Text('\uD83C\uDF89')
            .fontSize(34)
        }
        .width(72)
        .height(72)
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
          Text('删除')
            .fontSize(12)
            .fontColor(Theme.danger)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.onDelete !== undefined) {
                this.onDelete();
              }
            })
        }
        .width('100%')

        Text(`${this.item.club} \u00B7 ${this.item.venue}`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width('100%')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.item.currentParticipants}/${this.item.maxParticipants}人 \u00B7 ${this.item.activityTime}`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width('100%')
          .margin({ top: 2 })
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
struct MyCarpoolCard {
  item: CarpoolOrder = new CarpoolOrder();
  onTap?: () => void;
  onDelete?: () => void;

  build() {
    Row() {
      Column() {
        Text('\uD83D\uDE97')
          .fontSize(34)
      }
      .width(72)
      .height(72)
      .backgroundColor(Theme.bgPage)
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(this.item.departure)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(' \u2192 ')
            .fontSize(14)
            .fontColor(Theme.textTertiary)
          Text(this.item.destination)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('删除')
            .fontSize(12)
            .fontColor(Theme.danger)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.onDelete !== undefined) {
                this.onDelete();
              }
            })
        }
        .width('100%')

        Text(`${this.item.departureTime} \u00B7 ${this.item.currentPassengers}/${this.item.maxPassengers}人`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width('100%')
          .margin({ top: 4 })

        if (this.item.remark.length > 0) {
          Text(this.item.remark)
            .fontSize(12)
            .fontColor(Theme.textTertiary)
            .width('100%')
            .margin({ top: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
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
struct MyConfessionCard {
  item: ConfessionPost = new ConfessionPost();
  onDelete: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text(this.item.category)
          .fontSize(11)
          .fontColor(Theme.primary)
          .backgroundColor(Theme.primaryLight)
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        Blank()
        Text('删除')
          .fontSize(12)
          .fontColor(Theme.danger)
          .onClick(() => { this.onDelete() })
      }
      .width('100%')

      Text(this.item.content)
        .fontSize(14)
        .fontColor(Theme.textPrimary)
        .width('100%')
        .margin({ top: 8 })

      if (this.item.images.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.item.images, (imgUrl: string, index: number) => {
            Image(ApiService.baseUrl + imgUrl)
              .width(this.item.images.length === 1 ? 200 : 100)
              .height(this.item.images.length === 1 ? 200 : 100)
              .borderRadius(6)
              .objectFit(ImageFit.Cover)
              .margin({ right: 4, bottom: 4 })
          }, (imgUrl: string, index: number) => `${index}`)
        }
        .width('100%')
        .margin({ top: 8 })
      }

      Row() {
        Text(`\u2764 ${this.item.likeCount}`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
        Text(`\uD83D\uDCAC ${this.item.commentCount}`)
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .margin({ left: 12 })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
}

@Component
struct MyStudyShareCard {
  item: StudyShareItem = new StudyShareItem();
  onTap?: () => void;
  onDelete?: () => void;

  build() {
    Row() {
      Column() {
        Text('\uD83D\uDCC4')
          .fontSize(34)
      }
      .width(72)
      .height(72)
      .backgroundColor(Theme.bgPage)
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(this.item.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('删除')
            .fontSize(12)
            .fontColor(Theme.danger)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.onDelete !== undefined) {
                this.onDelete();
              }
            })
        }
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
          Text(this.item.createTime)
            .fontSize(11)
            .fontColor(Theme.textTertiary)
        }
        .width('100%')
        .margin({ top: 4 })
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
  @State private activities: ClubActivityItem[] = [];
  @State private carpools: CarpoolOrder[] = [];
  @State private confessionPosts: ConfessionPost[] = [];
  @State private studyShares: StudyShareItem[] = [];
  @State private isLoggedIn: boolean = false;
  @State private productsLoaded: boolean = false;
  @State private activitiesLoaded: boolean = false;
  @State private carpoolsLoaded: boolean = false;
  @State private confessionLoaded: boolean = false;
  @State private studyLoaded: boolean = false;
  @State private productsLoading: boolean = true;
  @State private activitiesLoading: boolean = false;
  @State private carpoolsLoading: boolean = false;
  @State private confessionLoading: boolean = false;
  @State private studyLoading: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.loadTabData(0);
    } else {
      this.productsLoading = false;
    }
  }

  private async loadTabData(tabIndex: number): Promise<void> {
    if (tabIndex === 0 && !this.productsLoaded) {
      this.productsLoading = true;
      const result: ApiResult = await ApiService.getMyProducts();
      if (result.code === 200 && result.data !== undefined) {
        this.products = ApiService.parseProductList(result.data);
      }
      this.productsLoaded = true;
      this.productsLoading = false;
    } else if (tabIndex === 1 && !this.activitiesLoaded) {
      this.activitiesLoading = true;
      const result: ApiResult = await ApiService.getMyClubActivities(1, 100);
      if (result.code === 200 && result.data !== undefined) {
        this.activities = ApiService.parseClubActivityList(result.data);
      }
      this.activitiesLoaded = true;
      this.activitiesLoading = false;
    } else if (tabIndex === 2 && !this.carpoolsLoaded) {
      this.carpoolsLoading = true;
      const result: ApiResult = await ApiService.getMyCarpoolOrders();
      if (result.code === 200 && result.data !== undefined) {
        this.carpools = ApiService.parseCarpoolOrders(result.data);
      }
      this.carpoolsLoaded = true;
      this.carpoolsLoading = false;
    } else if (tabIndex === 3 && !this.confessionLoaded) {
      this.confessionLoading = true;
      const result: ApiResult = await ApiService.getMyConfessionPosts();
      if (result.code === 200 && result.data !== undefined) {
        this.confessionPosts = ApiService.parseConfessionPostList(result.data);
      }
      this.confessionLoaded = true;
      this.confessionLoading = false;
    } else if (tabIndex === 4 && !this.studyLoaded) {
      this.studyLoading = true;
      const result: ApiResult = await ApiService.getMyStudyShares();
      if (result.code === 200 && result.data !== undefined) {
        this.studyShares = ApiService.parseStudyShareList(result.data);
      }
      this.studyLoaded = true;
      this.studyLoading = false;
    }
  }

  private confirmDeleteConfession(postId: number): void {
    AlertDialog.show({
      message: '确定删除这条帖子吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => { this.doDeleteConfession(postId) } }
    });
  }

  private async doDeleteConfession(postId: number): Promise<void> {
    const result: ApiResult = await ApiService.deleteConfession(postId);
    if (result.code === 200) {
      this.confessionPosts = this.confessionPosts.filter((p: ConfessionPost) => p.id !== postId);
      this.getUIContext().getPromptAction().showToast({ message: '删除成功', duration: 1500 });
    } else {
      const msg: string = result.msg ?? '删除失败';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
    }
  }

  private confirmDeleteActivity(activityId: number): void {
    AlertDialog.show({
      message: '确定删除这个活动吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => { this.doDeleteActivity(activityId) } }
    });
  }

  private async doDeleteActivity(activityId: number): Promise<void> {
    const result: ApiResult = await ApiService.deleteClubActivity(activityId);
    if (result.code === 200) {
      this.activities = this.activities.filter((a: ClubActivityItem) => a.id !== activityId);
      this.getUIContext().getPromptAction().showToast({ message: '删除成功', duration: 1500 });
    } else {
      const msg: string = result.msg ?? '删除失败';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
    }
  }

  private confirmDeleteCarpool(orderId: number): void {
    AlertDialog.show({
      message: '确定删除这条拼车信息吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => { this.doDeleteCarpool(orderId) } }
    });
  }

  private async doDeleteCarpool(orderId: number): Promise<void> {
    const result: ApiResult = await ApiService.deleteCarpool(orderId);
    if (result.code === 200) {
      this.carpools = this.carpools.filter((c: CarpoolOrder) => c.id !== orderId);
      this.getUIContext().getPromptAction().showToast({ message: '删除成功', duration: 1500 });
    } else {
      const msg: string = result.msg ?? '删除失败';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
    }
  }

  private confirmDeleteStudyShare(shareId: number): void {
    AlertDialog.show({
      message: '确定删除这份资料吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => { this.doDeleteStudyShare(shareId) } }
    });
  }

  private async doDeleteStudyShare(shareId: number): Promise<void> {
    const result: ApiResult = await ApiService.deleteStudyShare(shareId);
    if (result.code === 200) {
      this.studyShares = this.studyShares.filter((s: StudyShareItem) => s.id !== shareId);
      this.getUIContext().getPromptAction().showToast({ message: '删除成功', duration: 1500 });
    } else {
      const msg: string = result.msg ?? '删除失败';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
    }
  }

  private async changeStatus(product: Product, status: number): Promise<void> {
    const result: ApiResult = await ApiService.updateProductStatus(product.id, status);
    if (result.code === 200) {
      product.status = status;
      this.products = this.products.slice();
      this.getUIContext().getPromptAction().showToast({ message: status === 1 ? '已上架' : '已下架', duration: 1500 });
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
      this.getUIContext().getPromptAction().showToast({ message: '已删除', duration: 1500 });
    } else {
      AlertDialog.show({
        message: result.msg || '删除失败',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private onTabChange(index: number): void {
    this.loadTabData(index);
  }

  @Builder
  productListBuilder() {
    if (this.productsLoading && !this.productsLoaded) {
      Column() {
        LoadingProgress().color(Theme.secondary).width(40).height(40)
      }.width('100%').layoutWeight(1).padding({ top: 80 })
    } else if (this.products.length === 0) {
      Column() {
        Text('\uD83D\uDCE6')
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
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 80 })
    } else {
      Scroll() {
        Column() {
          Row() {
            Text(`共 ${this.products.length} 件发布`)
              .fontSize(13)
              .fontColor(Theme.textSecondary)
            Blank()
            if (this.productsLoading) {
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
                onTap: () => {
                  router.pushUrl({ url: 'pages/ProductDetailPage', params: { 'productId': item.id } as Record<string, Object> });
                },
                onStatusChange: (status: number) => this.changeStatus(item, status),
                onDelete: () => this.deleteProduct(item)
              })
            }, (item: Product) => item.id.toString())
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 20 })
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

  @Builder
  activityListBuilder() {
    if (this.activitiesLoading && !this.activitiesLoaded) {
      Column() {
        LoadingProgress().color(Theme.secondary).width(40).height(40)
      }.width('100%').layoutWeight(1).padding({ top: 80 })
    } else if (this.activities.length === 0) {
      Column() {
        Text('\uD83C\uDF89')
          .fontSize(64)
        Text('还没有发布活动')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 80 })
    } else {
      Scroll() {
        Column() {
          ForEach(this.activities, (item: ClubActivityItem) => {
            MyActivityCard({
              item: item,
              onTap: () => {
                  router.pushUrl({ url: 'pages/ClubActivityDetailPage', params: { 'id': item.id } as Record<string, Object> });
              },
              onDelete: () => { this.confirmDeleteActivity(item.id) }
            })
          }, (item: ClubActivityItem) => `${item.id}`)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  carpoolListBuilder() {
    if (this.carpoolsLoading && !this.carpoolsLoaded) {
      Column() {
        LoadingProgress().color(Theme.secondary).width(40).height(40)
      }.width('100%').layoutWeight(1).padding({ top: 80 })
    } else if (this.carpools.length === 0) {
      Column() {
        Text('\uD83D\uDE97')
          .fontSize(64)
        Text('还没有发布拼车')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 80 })
    } else {
      Scroll() {
        Column() {
          ForEach(this.carpools, (item: CarpoolOrder) => {
            MyCarpoolCard({
              item: item,
              onTap: () => {
                  router.pushUrl({ url: 'pages/CarpoolDetailPage', params: { 'id': `${item.id}` } as Record<string, string> });
              },
              onDelete: () => { this.confirmDeleteCarpool(item.id) }
            })
          }, (item: CarpoolOrder) => `${item.id}`)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  confessionListBuilder() {
    if (this.confessionLoading && !this.confessionLoaded) {
      Column() {
        LoadingProgress().color(Theme.secondary).width(40).height(40)
      }.width('100%').layoutWeight(1).padding({ top: 80 })
    } else if (this.confessionPosts.length === 0) {
      Column() {
        Text('\uD83D\uDC95')
          .fontSize(64)
        Text('还没有发布表白墙')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 80 })
    } else {
      Scroll() {
        Column() {
          ForEach(this.confessionPosts, (item: ConfessionPost) => {
            MyConfessionCard({
              item: item,
              onDelete: () => { this.confirmDeleteConfession(item.id) }
            })
          }, (item: ConfessionPost) => `${item.id}`)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  studyShareListBuilder() {
    if (this.studyLoading && !this.studyLoaded) {
      Column() {
        LoadingProgress().color(Theme.secondary).width(40).height(40)
      }.width('100%').layoutWeight(1).padding({ top: 80 })
    } else if (this.studyShares.length === 0) {
      Column() {
        Text('\uD83D\uDCC4')
          .fontSize(64)
        Text('还没有发布资料')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 80 })
    } else {
      Scroll() {
        Column() {
          ForEach(this.studyShares, (item: StudyShareItem) => {
            MyStudyShareCard({
              item: item,
              onTap: () => {
                  router.pushUrl({ url: 'pages/StudyShareDetailPage', params: { 'id': item.id } as Record<string, Object> });
              },
              onDelete: () => { this.confirmDeleteStudyShare(item.id) }
            })
          }, (item: StudyShareItem) => `${item.id}`)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  build() {
    Column() {
      NavHeader({ title: '我的发布' })

      if (!this.isLoggedIn) {
        Column() {
          Text('\uD83D\uDD12')
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
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 80 })
      } else if (this.productsLoading && !this.productsLoaded) {
        Column() {
          LoadingProgress()
            .color(Theme.secondary)
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 80 })
      } else {
        Tabs({ barPosition: BarPosition.Start }) {
          TabContent() {
            this.productListBuilder()
          }
          .tabBar('商品')

          TabContent() {
            this.activityListBuilder()
          }
          .tabBar('活动')

          TabContent() {
            this.carpoolListBuilder()
          }
          .tabBar('拼车')

          TabContent() {
            this.confessionListBuilder()
          }
          .tabBar('表白墙')

          TabContent() {
            this.studyShareListBuilder()
          }
          .tabBar('资料')
        }
        .scrollable(true)
        .barMode(BarMode.Scrollable)
        .width('100%')
        .layoutWeight(1)
        .onChange((index: number) => {
          this.onTabChange(index);
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
