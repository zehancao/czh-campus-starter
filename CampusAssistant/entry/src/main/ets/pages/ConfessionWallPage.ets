import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { ConfessionPost, ConfessionComment } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';
import { AvatarView } from '../common/AvatarView';
import { AppStore } from '../service/AppStore';

const CATEGORY_TABS: string[] = ['全部', '表白', '树洞', '吐槽', '交友'];
const CATEGORY_COLORS: string[] = [Theme.ocean, '#DB2777', Theme.ocean, Theme.primary, '#7C3AED'];
const CATEGORY_BG_COLORS: string[] = [Theme.oceanLight, '#FCE7F3', Theme.oceanLight, Theme.primaryLight, '#F3E8FF'];
const PAGE_SIZE: number = 20;

@Entry
@Component
struct ConfessionWallPage {
  @State private posts: ConfessionPost[] = [];
  @State private activeTab: number = 0;
  @State private isLoading: boolean = true;
  @State private currentPage: number = 1;
  @State private hasMore: boolean = true;
  @State private isLoadingMore: boolean = false;
  @State private showImagePreview: boolean = false;
  @State private previewImages: string[] = [];
  @State private previewIndex: number = 0;
  @State private expandedComments: Record<string, boolean> = {};
  @State private commentInputs: Record<string, string> = {};
  @State private showCommentInput: boolean = false;
  @State private commentingPostId: number = 0;
  @State private commentList: ConfessionComment[] = [];

  onPageShow(): void {
    this.refreshList();
  }

  private async refreshList(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 1;
    this.hasMore = true;
    const category: string = this.activeTab === 0 ? '' : CATEGORY_TABS[this.activeTab];
    const result = await ApiService.getConfessionList(category, 1, PAGE_SIZE);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      this.posts = this.parsePosts(arr);
      this.hasMore = arr.length >= PAGE_SIZE;
    } else {
      this.posts = [];
      this.hasMore = false;
    }
    this.isLoading = false;
  }

  private async loadMore(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) return;
    this.isLoadingMore = true;
    this.currentPage = this.currentPage + 1;
    const category: string = this.activeTab === 0 ? '' : CATEGORY_TABS[this.activeTab];
    const result = await ApiService.getConfessionList(category, this.currentPage, PAGE_SIZE);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const newPosts: ConfessionPost[] = this.parsePosts(arr);
      for (let i = 0; i < newPosts.length; i++) {
        this.posts.push(newPosts[i]);
      }
      this.hasMore = arr.length >= PAGE_SIZE;
    } else {
      this.hasMore = false;
    }
    this.isLoadingMore = false;
  }

  private parsePosts(arr: Object[]): ConfessionPost[] {
    const list: ConfessionPost[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: ConfessionPost = new ConfessionPost();
      item.id = (obj['id'] as number) ?? 0;
      item.userId = (obj['userId'] as number) ?? 0;
      item.publisherName = (obj['publisherName'] as string) ?? '';
      item.publisherAvatar = (obj['publisherAvatar'] as string) ?? '';
      item.content = (obj['content'] as string) ?? '';
      const imgObj: Object = obj['images'];
      if (imgObj !== null && imgObj !== undefined) {
        const imgArr: Object[] = imgObj as Object[];
        item.images = [];
        for (let j = 0; j < imgArr.length; j++) {
          item.images.push(imgArr[j] as string);
        }
      }
      item.category = (obj['category'] as string) ?? '树洞';
      item.isAnonymous = (obj['isAnonymous'] as number) ?? 0;
      item.likeCount = (obj['likeCount'] as number) ?? 0;
      item.commentCount = (obj['commentCount'] as number) ?? 0;
      item.liked = (obj['liked'] as boolean) ?? false;
      item.status = (obj['status'] as number) ?? 0;
      item.createTime = (obj['createTime'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  private onTabChange(index: number): void {
    this.activeTab = index;
    this.refreshList();
  }

  private goToPublish(): void {
    router.pushUrl({ url: 'pages/ConfessionPublishPage' });
  }

  private async toggleLike(item: ConfessionPost): Promise<void> {
    const result = await ApiService.likeConfession(item.id);
    if (result.code === 200) {
      this.refreshList();
    }
  }

  private confirmDelete(item: ConfessionPost): void {
    AlertDialog.show({
      message: '确定删除这条帖子吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: () => { this.doDeleteConfession(item.id) }
      }
    });
  }

  private async doDeleteConfession(postId: number): Promise<void> {
    const result = await ApiService.deleteConfession(postId);
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '删除成功', duration: 1500 });
      this.refreshList();
    } else {
      const msg: string = result.msg ?? '删除失败';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
    }
  }

  private openImagePreview(images: string[], index: number): void {
    this.previewImages = images;
    this.previewIndex = index;
    this.showImagePreview = true;
  }

  private formatTime(timeStr: string): string {
    if (timeStr.length === 0) return '';
    const t: string = timeStr.replace('T', ' ');
    if (t.length > 16) return t.substring(0, 16);
    return t;
  }

  private getCategoryIndex(category: string): number {
    if (category === '表白') return 1;
    if (category === '树洞') return 2;
    if (category === '吐槽') return 3;
    if (category === '交友') return 4;
    return 0;
  }

  private getRelativeTime(timeStr: string): string {
    if (timeStr.length === 0) return '';
    const t: string = timeStr.replace('T', ' ');
    const timestamp: number = Date.parse(t);
    if (isNaN(timestamp)) return t;
    const diff: number = Date.now() - timestamp;
    const minutes: number = Math.floor(diff / 60000);
    if (minutes < 1) return '刚刚';
    if (minutes < 60) return `${minutes}分钟前`;
    const hours: number = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}小时前`;
    const days: number = Math.floor(hours / 24);
    if (days < 7) return `${days}天前`;
    return this.formatTime(timeStr);
  }

  private async loadComments(postId: number): Promise<void> {
    const result = await ApiService.getConfessionDetail(postId);
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      const commentsObj: Object = obj['comments'];
      if (commentsObj !== null && commentsObj !== undefined) {
        const arr: Object[] = commentsObj as Object[];
        this.commentList = [];
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
          this.commentList.push(comment);
        }
      }
    }
  }

  private async openCommentInput(postId: number): Promise<void> {
    this.commentingPostId = postId;
    this.showCommentInput = true;
    await this.loadComments(postId);
  }

  private async submitComment(): Promise<void> {
    const inputKey: string = `post_${this.commentingPostId}`;
    const content: string = this.commentInputs[inputKey] ?? '';
    if (content.trim().length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入评论内容', duration: 2000 });
      return;
    }
    const result = await ApiService.commentConfession(this.commentingPostId, content.trim(), 0);
    if (result.code === 200) {
      this.commentInputs[inputKey] = '';
      this.showCommentInput = false;
      this.getUIContext().getPromptAction().showToast({ message: '评论成功', duration: 1500 });
      this.refreshList();
    } else {
      this.getUIContext().getPromptAction().showToast({ message: '评论失败', duration: 2000 });
    }
  }

  build() {
    Stack() {
      Column() {
        NavHeader({ title: '表白墙' }) {
          Text('发布').fontSize(14).fontColor(Theme.primary).onClick(() => { this.goToPublish() })
        }

        Row() {
          ForEach(CATEGORY_TABS, (tab: string, index: number) => {
            Column() {
              Text(tab)
                .fontSize(14)
                .fontColor(this.activeTab === index ? CATEGORY_COLORS[index] : Theme.textSecondary)
                .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Regular)
              Divider()
                .height(2)
                .width(24)
                .color(this.activeTab === index ? CATEGORY_COLORS[index] : 'transparent')
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

        if (this.isLoading) {
          Column() {
            LoadingProgress().color(Theme.primary).width(36).height(36)
          }
          .width('100%').layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 0 }) {
            ForEach(this.posts, (item: ConfessionPost) => {
              ListItem() {
                this.PostCard(item)
              }
            }, (item: ConfessionPost) => `${item.id}`)

            if (this.posts.length === 0) {
              ListItem() {
                Column() {
                  Text('💌').fontSize(56)
                  Text('暂无帖子')
                    .fontSize(15).fontColor(Theme.textSecondary).margin({ top: 8 })
                  Text('点击右上角"发布"说点什么吧')
                    .fontSize(13).fontColor(Theme.textTertiary).margin({ top: 4 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .margin({ top: 40 })
              }
            }

            ListItem() {
              Column() {
                if (this.isLoadingMore) {
                  Row() {
                    LoadingProgress().width(20).height(20).color(Theme.primary)
                    Text('加载更多...')
                      .fontSize(13).fontColor(Theme.textTertiary).margin({ left: 8 })
                  }
                  .justifyContent(FlexAlign.Center)
                } else if (!this.hasMore && this.posts.length > 0) {
                  Text('- 没有更多了 -')
                    .fontSize(12).fontColor(Theme.textDisabled)
                }
              }
              .width('100%').padding({ top: 12, bottom: 12 }).alignItems(HorizontalAlign.Center)
            }
          }
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring)
          .padding({ left: 0, right: 0, top: 0, bottom: 20 })
          .onReachEnd(() => { this.loadMore() })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.bgPage)

      if (this.showImagePreview) {
        this.ImagePreviewOverlay()
      }

      if (this.showCommentInput) {
        this.CommentInputOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PostCard(item: ConfessionPost) {
    Column() {
      Row() {
        AvatarView({ avatar: item.isAnonymous === 1 ? '' : item.publisherAvatar, name: item.publisherName, avatarSize: 36 })
        Column() {
          Text(item.isAnonymous === 1 ? '匿名用户' : item.publisherName)
            .fontSize(14)
            .fontColor(Theme.textPrimary)
            .fontWeight(FontWeight.Medium)
          Row() {
            Text(this.getRelativeTime(item.createTime))
              .fontSize(11)
              .fontColor(Theme.textTertiary)
            Text(item.category)
              .fontSize(9)
              .fontColor(CATEGORY_COLORS[this.getCategoryIndex(item.category)])
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(6)
              .backgroundColor(CATEGORY_BG_COLORS[this.getCategoryIndex(item.category)])
              .margin({ left: 6 })
          }
          .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        if (AppStore.getInstance().isLoggedIn && AppStore.getInstance().userInfo.id === item.userId) {
          Blank()
          Text('删除')
            .fontSize(12)
            .fontColor(Theme.textTertiary)
            .onClick(() => { this.confirmDelete(item) })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (item.content.length > 0) {
        Text(item.content)
          .fontSize(15)
          .fontColor(Theme.textPrimary)
          .width('100%')
          .margin({ top: 10 })
          .lineHeight(22)
      }

      if (item.images.length > 0) {
        this.ImageGrid(item.images)
      }

      Row() {
        Row() {
          Text(item.liked ? '❤️' : '🤍')
            .fontSize(16)
          Text(`${item.likeCount}`)
            .fontSize(12)
            .fontColor(item.liked ? Theme.danger : Theme.textTertiary)
            .margin({ left: 4 })
        }
        .onClick(() => { this.toggleLike(item) })

        Row() {
          Text('💬')
            .fontSize(16)
          Text(`${item.commentCount}`)
            .fontSize(12)
            .fontColor(Theme.textTertiary)
            .margin({ left: 4 })
        }
        .margin({ left: 24 })
        .onClick(() => { this.openCommentInput(item.id) })
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 1 })
  }

  @Builder
  ImageGrid(images: string[]) {
    if (images.length === 1) {
      Image(`${ApiService.baseUrl}${images[0]}`)
        .width(200)
        .height(200)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .margin({ top: 10 })
        .onClick(() => { this.openImagePreview(images, 0) })
    } else {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(images, (img: string, index: number) => {
          Image(`${ApiService.baseUrl}${img}`)
            .width((AppStorage.get<number>('screenWidth') ?? 360) / 3 - 20)
            .height((AppStorage.get<number>('screenWidth') ?? 360) / 3 - 20)
            .borderRadius(6)
            .objectFit(ImageFit.Cover)
            .margin({ top: 4, right: 4 })
            .onClick(() => { this.openImagePreview(images, index) })
        }, (img: string, index: number) => `${index}-${img}`)
      }
      .margin({ top: 10 })
    }
  }

  @Builder
  ImagePreviewOverlay() {
    Column() {
      Row() {
        Text('✕')
          .fontSize(22)
          .fontColor('#FFFFFF')
          .margin({ left: 16 })
          .onClick(() => { this.showImagePreview = false })
        Blank()
        Text(`${this.previewIndex + 1}/${this.previewImages.length}`)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .margin({ right: 16 })
      }
      .width('100%')
      .height(56)

      Swiper() {
        ForEach(this.previewImages, (img: string) => {
          Image(`${ApiService.baseUrl}${img}`)
            .width('100%')
            .objectFit(ImageFit.Contain)
        }, (img: string, index: number) => `${index}`)
      }
      .index(this.previewIndex)
      .layoutWeight(1)
      .indicator(false)
      .onChange((index: number) => { this.previewIndex = index })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .position({ x: 0, y: 0 })
  }

  @Builder
  CommentInputOverlay() {
    Column() {
      Blank()

      Column() {
        if (this.commentList.length > 0) {
          Column() {
            ForEach(this.commentList, (c: ConfessionComment) => {
              Row() {
                Text(c.isAnonymous === 1 ? '匿名' : c.nickname)
                  .fontSize(13)
                  .fontColor(Theme.primary)
                  .fontWeight(FontWeight.Medium)
                Text(': ')
                  .fontSize(13)
                  .fontColor(Theme.textTertiary)
                Text(c.content)
                  .fontSize(13)
                  .fontColor(Theme.textPrimary)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })
            }, (c: ConfessionComment) => `${c.id}`)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(Theme.bgPage)
        }

        Row() {
          TextInput({ placeholder: '写评论...', text: $$this.commentInputs[`post_${this.commentingPostId}`] })
            .layoutWeight(1)
            .height(36)
            .borderRadius(18)
            .backgroundColor('#F5F5F5')
            .padding({ left: 14, right: 14 })

          Button('发送')
            .height(32)
            .fontSize(13)
            .backgroundColor(Theme.primary)
            .fontColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 8 })
            .onClick(() => { this.submitComment() })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.3)')
    .position({ x: 0, y: 0 })
    .onClick(() => { this.showCommentInput = false })
  }
}
