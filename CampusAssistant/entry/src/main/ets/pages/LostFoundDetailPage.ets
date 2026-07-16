
import { router } from '@kit.ArkUI';
import { http } from '@kit.NetworkKit';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { LostFoundItem } from '../model/Models';

const STATUS_LABELS: string[] = ['进行中', '已找到/已归还'];
const STATUS_COLORS: string[] = ['#F59E0B', '#10B981'];

function splitImageString(imagesStr: string): string[] {
  if (imagesStr === null || imagesStr === undefined || imagesStr.length === 0) {
    return [];
  }
  const cleaned: string = imagesStr.replace('[', '').replace(']', '').replace(new RegExp('"', 'g'), '');
  if (cleaned.length === 0) {
    return [];
  }
  return cleaned.split(',');
}

@Component
struct ImagePreview {
  private images: string[] = [];
  private startIndex: number = 0;

  build() {
    if (this.images.length === 0) {
      Column() {
        Text('📷 暂无图片').fontSize(32).fontColor('#D1D5DB')
      }
      .width('100%').height(280)
      .backgroundColor('#F9FAFB')
      .justifyContent(FlexAlign.Center)
    } else {
      Stack() {
        Swiper() {
          ForEach(this.images, (img: string) => {
            Image(ApiService.baseUrl + img)
              .width('100%')
              .height(280)
              .objectFit(ImageFit.Cover)
          }, (img: string) => img)
        }
        .width('100%')
        .height(280)
        .autoPlay(false)
        .indicator(false)
        .loop(false)
        .onChange((index: number) => { this.startIndex = index })
       if (this.images.length > 1) {
          Text((this.startIndex + 1) + '/' + this.images.length)
            .fontSize(12).fontColor('#FFFFFF')
            .backgroundColor('#00000066')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .position({ bottom: 12, right: 12 })
        }
      }
    }
  }
}

@Entry
@Component
struct LostFoundDetailPage {
  @State private itemData: LostFoundItem = new LostFoundItem();
  @State private images: string[] = [];
  @State private isLoading: boolean = true;
  @State private isMyPost: boolean = false;
  @State private errorMsg: string = '';

  private lostFoundIdInput: number = 0;

  aboutToAppear(): void {
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params !== undefined && params !== null) {
      const idObj: Object = params['id'];
      if (idObj !== undefined && idObj !== null) {
        this.lostFoundIdInput = parseInt(idObj as string, 10);
      }
    }
    if (this.lostFoundIdInput > 0) {
      this.loadDetail();
    } else {
      this.errorMsg = '参数错误';
      this.isLoading = false;
    }
  }

  private async loadDetail(): Promise<void> {
    this.isLoading = true;
    try {
      const result = await ApiService.request(
        http.RequestMethod.GET,
        '/api/lost-found/detail?id=' + this.lostFoundIdInput,
        undefined, false
      );
      if (result.code === 200 && result.data !== undefined) {
        const obj: Record<string, Object> = result.data as Record<string, Object>;
        const lf: LostFoundItem = new LostFoundItem();
        lf.id = (obj['id'] as number) ?? 0;
        lf.userId = (obj['userId'] as number) ?? 0;
        lf.userName = (obj['userName'] as string) ?? '';
        lf.type = (obj['type'] as number) ?? 1;
        lf.title = (obj['title'] as string) ?? '';
        lf.description = (obj['description'] as string) ?? '';
        const imgObj: Object = obj['images'];
        if (imgObj !== null && imgObj !== undefined) {
          lf.images = imgObj as string;
        } else {
          lf.images = '[]';
        }
        lf.locationDesc = (obj['locationDesc'] as string) ?? '';
        lf.category = (obj['category'] as string) ?? '';
        const phoneObj: Object = obj['contactPhone'];
        if (phoneObj !== null && phoneObj !== undefined) {
          lf.contactPhone = phoneObj as string;
        } else {
          lf.contactPhone = '';
        }
        lf.status = (obj['status'] as number) ?? 1;
        lf.createTime = (obj['createTime'] as string) ?? '';
        this.itemData = lf;
        this.images = splitImageString(lf.images);

        const store: AppStore = AppStore.getInstance();
        if (store.isLoggedIn && store.userInfo.id === lf.userId) {
          this.isMyPost = true;
        }
      } else {
        this.errorMsg = result.msg || '加载失败';
      }
    } catch (err) {
      this.errorMsg = '网络错误';
    }
    this.isLoading = false;
  }

  private deletePost(): void {
    if (!this.isMyPost) {
      return;
    }
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条' + (this.itemData.type === 1 ? '寻物' : '招领') + '信息吗？此操作不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      confirm: {
        value: '删除',
        fontColor: '#EF4444',
        action: () => {
          this.doDelete();
        }
      }
    });
  }

  private async doDelete(): Promise<void> {
    const result = await ApiService.deleteLostFound(this.itemData.id);
    if (result.code === 200) {
      promptAction.showToast({ message: '已删除' });
      router.back();
    } else {
      AlertDialog.show({
        message: result.msg || '删除失败',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private contactOwner(): void {
    const store: AppStore = AppStore.getInstance();
    if (!store.isLoggedIn) {
      AlertDialog.show({
        message: '请先登录后联系',
        confirm: { value: '好的', action: () => {} }
      });
      return;
    }
    AlertDialog.show({
      message: '联系 ' + this.itemData.userName + '：\n' + this.itemData.contactPhone,
      confirm: { value: '好的', action: () => {} }
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹ 返回')
          .fontSize(16).fontColor('#6B7280')
          .onClick(() => { router.back() })
        Blank()
        Text(this.itemData.type === 1 ? '寻物信息' : '招领信息')
          .fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        if (this.isMyPost && !this.isLoading) {
          Text('删除')
            .fontSize(15).fontColor('#EF4444')
            .onClick(() => { this.deletePost() })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress().color('#FF6B35').width(36).height(36)
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMsg.length > 0) {
        Column() {
          Text('😕').fontSize(48)
          Text(this.errorMsg).fontSize(16).fontColor('#6B7280').margin({ top: 12 })
          Button('重试')
            .type(ButtonType.Capsule).backgroundColor('#FF6B35').fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { this.loadDetail() })
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ImagePreview({ images: this.images, startIndex: 0 })

            Row() {
              Text(this.itemData.type === 1 ? '🔍 寻物' : '📢 招领')
                .fontSize(14).fontColor('#FF6B35')
                .backgroundColor('#FFF3ED')
                .borderRadius(6)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              Blank()
              Text(STATUS_LABELS[Math.max(0, Math.min(this.itemData.status - 1, 1))])
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor(STATUS_COLORS[Math.max(0, Math.min(this.itemData.status - 1, 1))])
                .borderRadius(4)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12 })

            Text(this.itemData.title)
              .fontSize(20).fontWeight(FontWeight.Bold)
              .width('100%')
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })

            Divider().height(8).color('#F3F4F6').width('100%').margin({ top: 12 })
            Column() {
              if (this.itemData.category.length > 0) {
                Row() {
                  Text('物品分类').fontSize(14).fontColor('#9CA3AF').width(80)
                  Text(this.itemData.category).fontSize(14).fontColor('#374151')
                  Blank()
                }
                .width('100%')
                .padding({ top: 6, bottom: 6 })
              }

              if (this.itemData.locationDesc.length > 0) {
                Row() {
                  Text('地    点').fontSize(14).fontColor('#9CA3AF').width(80)
                  Text(this.itemData.locationDesc).fontSize(14).fontColor('#374151')
                  Blank()
                }
                .width('100%')
                .padding({ top: 6, bottom: 6 })
              }

              Row() {
                Text('发布者').fontSize(14).fontColor('#9CA3AF').width(80)
                Text(this.itemData.userName).fontSize(14).fontColor('#374151')
                Blank()
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })

              Row() {
                Text('发布时间').fontSize(14).fontColor('#9CA3AF').width(80)
                Text(this.formatTime(this.itemData.createTime)).fontSize(14).fontColor('#374151')
                Blank()
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })

              Divider().height(1).color('#E5E7EB').width('100%').margin({ top: 6, bottom: 6 })

              Row() {
                Text('详细描述').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#374151')
                Blank()
              }
              .width('100%')
              Text(this.itemData.description.length > 0 ? this.itemData.description : '暂无描述')
                .fontSize(14).fontColor('#6B7280')
                .width('100%')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')

            Divider().height(8).color('#F3F4F6').width('100%')

            if (this.itemData.contactPhone.length > 0) {
              Column() {
                Row() {
                  Text('联系方式').fontSize(14).fontWeight(FontWeight.Medium)
                  Blank()
                }
                .width('100%')
                Row() {
                  Text('📞').fontSize(20)
                  Text(this.itemData.contactPhone)
                    .fontSize(16).fontColor('#FF6B35')
                    .margin({ left: 8 })
                  Blank()
                }
                .width('100%')
                .margin({ top: 8 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
            }

            Divider().height(16).color('#F3F4F6').width('100%')
          }
        }
        .layoutWeight(1)
        .width('100%')

        Row() {
          Button('📞 联系 ' + (this.itemData.userName.length > 0 ? this.itemData.userName : '发布者'))
            .type(ButtonType.Capsule)
            .backgroundColor('#FF6B35')
            .fontColor('#FFFFFF')
            .borderRadius(22)
            .height(44)
            .layoutWeight(1)
            .margin({ left: 16, right: 16 })
            .onClick(() => { this.contactOwner() })
        }
        .width('100%')
        .height(64)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 4, color: '#0000001A', offsetY: -2 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
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
