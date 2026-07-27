import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { ConfessionPost, ConfessionComment } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const CATEGORY_COLORS: Record<string, string> = {
  '表白': '#DB2777',
  '树洞': Theme.ocean,
  '吐槽': Theme.primary,
  '交友': '#7C3AED'
};
const CATEGORY_BG: Record<string, string> = {
  '表白': '#FCE7F3',
  '树洞': Theme.oceanLight,
  '吐槽': Theme.primaryLight,
  '交友': '#F3E8FF'
};

function splitImageString(imagesStr: string): string[] {
  if (imagesStr === null || imagesStr === undefined || imagesStr.length === 0) return [];
  const cleaned: string = imagesStr.replace('[', '').replace(']', '').replace(new RegExp('"', 'g'), '');
  if (cleaned.length === 0) return [];
  return cleaned.split(',');
}

@Entry
@Component
struct ConfessionDetailPage {
  @State private post: ConfessionPost = new ConfessionPost();
  @State private comments: ConfessionComment[] = [];
  @State private images: string[] = [];
  @State private isLoading: boolean = true;
  @State private isMyPost: boolean = false;
  @State private errorMsg: string = '';
  @State private commentInput: string = '';
  @State private commentAnonymous: number = 0;
  @State private isSubmitting: boolean = false;
  @State private swiperIndex: number = 0;

  private postId: number = 0;

  aboutToAppear(): void {
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params !== undefined && params !== null) {
      const idObj: Object = params['id'];
      if (idObj !== undefined && idObj !== null) {
        this.postId = parseInt(idObj as string, 10);
      }
    }
    if (this.postId > 0) {
      this.loadDetail();
    } else {
      this.errorMsg = '参数错误';
      this.isLoading = false;
    }
  }

  private async loadDetail(): Promise<void> {
    this.isLoading = true;
    const result = await ApiService.getConfessionDetail(this.postId);
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      this.post.id = (obj['id'] as number) ?? 0;
      this.post.userId = (obj['userId'] as number) ?? 0;
      this.post.publisherName = (obj['publisherName'] as string) ?? '';
      this.post.publisherAvatar = (obj['publisherAvatar'] as string) ?? '';
      this.post.content = (obj['content'] as string) ?? '';
      const imgObj: Object = obj['images'];
      if (imgObj !== null && imgObj !== undefined) {
        const imgArr: Object[] = imgObj as Object[];
        this.post.images = [];
        for (let j = 0; j < imgArr.length; j++) {
          this.post.images.push(imgArr[j] as string);
        }
      }
      this.post.category = (obj['category'] as string) ?? '树洞';
      this.post.isAnonymous = (obj['isAnonymous'] as number) ?? 0;
      this.post.likeCount = (obj['likeCount'] as number) ?? 0;
      this.post.commentCount = (obj['commentCount'] as number) ?? 0;
      this.post.liked = (obj['liked'] as boolean) ?? false;
      this.post.status = (obj['status'] as number) ?? 0;
      this.post.createTime = (obj['createTime'] as string) ?? '';
      this.images = this.post.images;

      const commentsObj: Object = obj['comments'];
      if (commentsObj !== null && commentsObj !== undefined) {
        const arr: Object[] = commentsObj as Object[];
        this.comments = [];
        for (let i = 0; i < arr.length; i++) {
          const c: Record<string, Object> = arr[i] as Record<string, Object>;
          const comment: ConfessionComment = new ConfessionComment();
          comment.id = (c['id'] as number) ?? 0;
          comment.userId = (c['userId'] as number) ?? 0;
          comment.nickname = (c['nickname'] as string) ?? '';
          comment.avatar = (c['avatar'] as string) ?? '';
          comment.content = (c['content'] as string) ?? '';
          comment.isAnonymous = (c['isAnonymous'] as number) ?? 0;
          comment.createTime = (c['createTime'] as string) ?? '';
          this.comments.push(comment);
        }
      }

      const store: AppStore = AppStore.getInstance();
      if (store.isLoggedIn && store.userInfo.id === this.post.userId) {
        this.isMyPost = true;
      }
    } else {
      this.errorMsg = '加载失败';
    }
    this.isLoading = false;
  }

  private async toggleLike(): Promise<void> {
    const result = await ApiService.likeConfession(this.postId);
    if (result.code === 200) {
      this.loadDetail();
    }
  }

  private async submitComment(): Promise<void> {
    if (this.commentInput.trim().length === 0) return;
    this.isSubmitting = true;
    const result = await ApiService.commentConfession(this.postId, this.commentInput.trim(), this.commentAnonymous);
    this.isSubmitting = false;
    if (result.code === 200) {
      this.commentInput = '';
      promptAction.showToast({ message: '评论成功' });
      this.loadDetail();
    } else {
      promptAction.showToast({ message: '评论失败' });
    }
  }

  private deletePost(): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条帖子吗？',
      primaryButton: { value: '取消', action: () => {} },
      confirm: {
        value: '删除',
        fontColor: Theme.danger,
        action: () => { this.doDelete(); }
      }
    });
  }

  private async doDelete(): Promise<void> {
    const result = await ApiService.deleteConfession(this.postId);
    if (result.code === 200) {
      promptAction.showToast({ message: '已删除' });
      router.back();
    }
  }

  private formatTime(timeStr: string): string {
    if (timeStr.length === 0) return '';
    const t: string = timeStr.replace('T', ' ');
    if (t.length > 16) return t.substring(0, 16);
    return t;
  }

  private getCategoryColor(): string {
    const c: string | undefined = CATEGORY_COLORS[this.post.category];
    return c !== undefined ? c : Theme.ocean;
  }

  private getCategoryBg(): string {
    const b: string | undefined = CATEGORY_BG[this.post.category];
    return b !== undefined ? b : Theme.oceanLight;
  }

  build() {
    Column() {
      NavHeader({ title: '帖子详情' }) {
        if (this.isMyPost && !this.isLoading) {
          Text('删除').fontSize(14).fontColor(Theme.danger).onClick(() => { this.deletePost() })
        }
      }

      if (this.isLoading) {
        Column() {
          LoadingProgress().color(Theme.primary).width(36).height(36)
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMsg.length > 0) {
        Column() {
          Text('😕').fontSize(48)
          Text(this.errorMsg).fontSize(16).fontColor(Theme.textSecondary).margin({ top: 12 })
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Text(this.post.publisherName)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.textPrimary)
                Text(this.formatTime(this.post.createTime))
                  .fontSize(12)
                  .fontColor(Theme.textTertiary)
                  .margin({ left: 10 })
                Blank()
                Text(this.post.category)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.getCategoryColor())
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(10)
                  .backgroundColor(this.getCategoryBg())
              }
              .width('100%')

              Text(this.post.content)
                .fontSize(16)
                .fontColor(Theme.textPrimary)
                .width('100%')
                .margin({ top: 12 })
                .lineHeight(24)

              if (this.images.length > 0) {
                if (this.images.length === 1) {
                  Image(`${ApiService.baseUrl}${this.images[0]}`)
                    .width('100%')
                    .height(220)
                    .borderRadius(Theme.radiusMd)
                    .objectFit(ImageFit.Cover)
                    .margin({ top: 12 })
                } else {
                  Stack() {
                    Swiper() {
                      ForEach(this.images, (img: string) => {
                        Image(`${ApiService.baseUrl}${img}`)
                          .width('100%')
                          .height(220)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(Theme.radiusMd)
                      }, (img: string) => img)
                    }
                    .width('100%')
                    .height(220)
                    .autoPlay(false)
                    .indicator(false)
                    .loop(false)
                    .onChange((index: number) => { this.swiperIndex = index })

                    if (this.images.length > 1) {
                      Text(`${this.swiperIndex + 1}/${this.images.length}`)
                        .fontSize(12).fontColor('#FFFFFF')
                        .backgroundColor('#00000066')
                        .borderRadius(Theme.radiusSm)
                        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                        .position({ bottom: 8, right: 8 })
                    }
                  }
                  .width('100%')
                  .height(220)
                  .margin({ top: 12 })
                }
              }

              Row() {
                Row() {
                  Text(this.post.liked ? '❤️' : '🤍').fontSize(16)
                  Text(`${this.post.likeCount}`)
                    .fontSize(13)
                    .fontColor(this.post.liked ? Theme.danger : Theme.textTertiary)
                    .margin({ left: 4 })
                }
                .onClick(() => { this.toggleLike() })

                Row() {
                  Text('💬').fontSize(16)
                  Text(`${this.post.commentCount}`)
                    .fontSize(13)
                    .fontColor(Theme.textTertiary)
                    .margin({ left: 4 })
                }
                .margin({ left: 24 })
              }
              .margin({ top: 14 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(Theme.cardRadius)

            Divider().height(8).color(Theme.bgPage).width('100%')

            Column() {
              Text(`评论 (${this.comments.length})`)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
                .width('100%')
                .margin({ bottom: 12 })

              if (this.comments.length > 0) {
                ForEach(this.comments, (item: ConfessionComment) => {
                  Row() {
                    Column() {
                      Text(item.nickname)
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Theme.textPrimary)
                      Text(item.content)
                        .fontSize(14)
                        .fontColor(Theme.textSecondary)
                        .margin({ top: 4 })
                        .width('100%')
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Text(this.formatTime(item.createTime))
                      .fontSize(11)
                      .fontColor(Theme.textTertiary)
                  }
                  .width('100%')
                  .padding({ top: 10, bottom: 10 })
                  .alignItems(VerticalAlign.Top)
                }, (item: ConfessionComment) => `${item.id}`)
              } else {
                Text('暂无评论，来说点什么吧~')
                  .fontSize(13)
                  .fontColor(Theme.textTertiary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 20, bottom: 20 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(Theme.cardRadius)
          }
          .padding({ left: 12, right: 12, top: 8, bottom: 80 })
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)

        Row() {
          Row() {
            TextInput({ placeholder: '写评论...', text: this.commentInput })
              .layoutWeight(1)
              .height(40)
              .fontSize(14)
              .backgroundColor(Theme.bgInput)
              .borderRadius(20)
              .padding({ left: 16, right: 16 })
              .onChange((val: string) => { this.commentInput = val })
          }
          .layoutWeight(1)

          Text(this.commentAnonymous === 1 ? '🎭' : '😎')
            .fontSize(20)
            .margin({ left: 8 })
            .onClick(() => {
              this.commentAnonymous = this.commentAnonymous === 0 ? 1 : 0;
            })

          Button('发送')
            .type(ButtonType.Capsule)
            .height(36)
            .fontSize(13)
            .backgroundColor(this.commentInput.trim().length > 0 ? Theme.primary : Theme.textDisabled)
            .fontColor('#FFFFFF')
            .margin({ left: 8 })
            .enabled(this.commentInput.trim().length > 0 && !this.isSubmitting)
            .onClick(() => { this.submitComment() })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
        .shadow(ShadowStyle.md)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
