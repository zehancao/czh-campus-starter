import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { StudyShareItem } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const CATEGORY_TABS: string[] = ['全部', '课件', '笔记', '真题', '作业', '其他'];
const CATEGORY_COLORS: string[] = [Theme.primary, '#0288D1', Theme.ocean, '#D97706', Theme.success, Theme.textSecondary];
const CATEGORY_BG_COLORS: string[] = [Theme.primaryLight, '#E0F0FF', Theme.oceanLight, '#FFF9E6', Theme.successLight, '#F3F4F6'];

const FILE_TYPE_ICONS: Record<string, string> = {
  'pdf': '📄',
  'doc': '📝',
  'docx': '📝',
  'ppt': '📊',
  'pptx': '📊',
  'xls': '📈',
  'xlsx': '📈',
  'jpg': '🖼️',
  'jpeg': '🖼️',
  'png': '🖼️',
  'zip': '📦',
  'rar': '📦'
};

const PAGE_SIZE: number = 20;

@Component
struct ShareCard {
  private itemData: StudyShareItem = new StudyShareItem();
  private onTapCallback?: () => void;
  private onLikeCallback?: () => void;
  private onFavoriteCallback?: () => void;

  build() {
    Column() {
      Row() {
        Text(this.itemData.uploaderName)
          .fontSize(13)
          .fontColor(Theme.textSecondary)
        Text(this.formatTime(this.itemData.createTime))
          .fontSize(11)
          .fontColor(Theme.textTertiary)
          .margin({ left: 8 })
        Blank()
        Text(this.itemData.category)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(CATEGORY_COLORS[this.getCategoryIndex()])
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(10)
          .backgroundColor(CATEGORY_BG_COLORS[this.getCategoryIndex()])
      }
      .width('100%')

      Row() {
        if (this.itemData.coverImage.length > 0) {
          Image(`${ApiService.baseUrl}${this.itemData.coverImage}`)
            .width(60)
            .height(60)
            .borderRadius(Theme.radiusSm)
            .objectFit(ImageFit.Cover)
            .margin({ right: 12 })
        } else {
          Column() {
            Text(this.getFileIcon())
              .fontSize(24)
            Text(this.itemData.fileType.toUpperCase())
              .fontSize(9)
              .fontColor(Theme.textTertiary)
              .margin({ top: 2 })
          }
          .width(60)
          .height(60)
          .backgroundColor(Theme.bgInput)
          .borderRadius(Theme.radiusSm)
          .justifyContent(FlexAlign.Center)
          .margin({ right: 12 })
        }

        Column() {
          Text(this.itemData.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.textPrimary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          if (this.itemData.courseName.length > 0) {
            Text(`📚 ${this.itemData.courseName}`)
              .fontSize(12)
              .fontColor(Theme.ocean)
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          Row() {
            Text(this.formatFileSize(this.itemData.fileSize))
              .fontSize(11)
              .fontColor(Theme.textTertiary)
            Text('·')
              .fontSize(11)
              .fontColor(Theme.textTertiary)
              .margin({ left: 4, right: 4 })
            Text(`${this.itemData.downloadCount}次下载`)
              .fontSize(11)
              .fontColor(Theme.textTertiary)
          }
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .margin({ top: 10 })
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row() {
        Row() {
          Text(this.itemData.liked ? '❤️' : '🤍')
            .fontSize(14)
          Text(`${this.itemData.likeCount}`)
            .fontSize(12)
            .fontColor(this.itemData.liked ? Theme.danger : Theme.textTertiary)
            .margin({ left: 4 })
        }
        .onClick(() => {
          if (this.onLikeCallback !== undefined) {
            this.onLikeCallback();
          }
        })

        Row() {
          Text(this.itemData.favorited ? '⭐' : '☆')
            .fontSize(14)
          Text(`${this.itemData.favoriteCount}`)
            .fontSize(12)
            .fontColor(this.itemData.favorited ? '#D97706' : Theme.textTertiary)
            .margin({ left: 4 })
        }
        .margin({ left: 20 })
        .onClick(() => {
          if (this.onFavoriteCallback !== undefined) {
            this.onFavoriteCallback();
          }
        })
      }
      .margin({ top: 10 })
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

  private getCategoryIndex(): number {
    if (this.itemData.category === '课件') return 1;
    if (this.itemData.category === '笔记') return 2;
    if (this.itemData.category === '真题') return 3;
    if (this.itemData.category === '作业') return 4;
    if (this.itemData.category === '其他') return 5;
    return 0;
  }

  private getFileIcon(): string {
    const icon: string | undefined = FILE_TYPE_ICONS[this.itemData.fileType.toLowerCase()];
    return icon !== undefined ? icon : '📁';
  }

  private formatFileSize(bytes: number): string {
    if (bytes <= 0) return '';
    if (bytes < 1024) return `${bytes}B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
  }
}

@Entry
@Component
struct StudySharePage {
  @State private shares: StudyShareItem[] = [];
  @State private activeTab: number = 0;
  @State private isLoading: boolean = true;
  @State private searchInput: string = '';
  @State private currentPage: number = 1;
  @State private hasMore: boolean = true;
  @State private isLoadingMore: boolean = false;

  onPageShow(): void {
    this.refreshList();
  }

  private async refreshList(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 1;
    this.hasMore = true;
    const category: string = this.activeTab === 0 ? '' : CATEGORY_TABS[this.activeTab];
    const result = await ApiService.getStudyShareList(this.searchInput.trim(), category, 1, PAGE_SIZE);
    const newItems: StudyShareItem[] = [];
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        const item: StudyShareItem = new StudyShareItem();
        item.id = (obj['id'] as number) ?? 0;
        item.userId = (obj['userId'] as number) ?? 0;
        item.uploaderName = (obj['uploaderName'] as string) ?? '';
        item.uploaderAvatar = (obj['uploaderAvatar'] as string) ?? '';
        item.title = (obj['title'] as string) ?? '';
        item.description = (obj['description'] as string) ?? '';
        item.courseName = (obj['courseName'] as string) ?? '';
        item.category = (obj['category'] as string) ?? '其他';
        item.fileUrl = (obj['fileUrl'] as string) ?? '';
        item.fileType = (obj['fileType'] as string) ?? '';
        item.fileSize = (obj['fileSize'] as number) ?? 0;
        item.coverImage = (obj['coverImage'] as string) ?? '';
        item.likeCount = (obj['likeCount'] as number) ?? 0;
        item.favoriteCount = (obj['favoriteCount'] as number) ?? 0;
        item.downloadCount = (obj['downloadCount'] as number) ?? 0;
        item.liked = (obj['liked'] as boolean) ?? false;
        item.favorited = (obj['favorited'] as boolean) ?? false;
        item.status = (obj['status'] as number) ?? 0;
        item.createTime = (obj['createTime'] as string) ?? '';
        newItems.push(item);
      }
      this.hasMore = arr.length >= PAGE_SIZE;
    }
    this.shares = newItems;
    this.isLoading = false;
  }

  private async loadMore(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }
    this.isLoadingMore = true;
    this.currentPage = this.currentPage + 1;
    const category: string = this.activeTab === 0 ? '' : CATEGORY_TABS[this.activeTab];
    const result = await ApiService.getStudyShareList(this.searchInput.trim(), category, this.currentPage, PAGE_SIZE);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        const item: StudyShareItem = new StudyShareItem();
        item.id = (obj['id'] as number) ?? 0;
        item.userId = (obj['userId'] as number) ?? 0;
        item.uploaderName = (obj['uploaderName'] as string) ?? '';
        item.uploaderAvatar = (obj['uploaderAvatar'] as string) ?? '';
        item.title = (obj['title'] as string) ?? '';
        item.description = (obj['description'] as string) ?? '';
        item.courseName = (obj['courseName'] as string) ?? '';
        item.category = (obj['category'] as string) ?? '其他';
        item.fileUrl = (obj['fileUrl'] as string) ?? '';
        item.fileType = (obj['fileType'] as string) ?? '';
        item.fileSize = (obj['fileSize'] as number) ?? 0;
        item.coverImage = (obj['coverImage'] as string) ?? '';
        item.likeCount = (obj['likeCount'] as number) ?? 0;
        item.favoriteCount = (obj['favoriteCount'] as number) ?? 0;
        item.downloadCount = (obj['downloadCount'] as number) ?? 0;
        item.liked = (obj['liked'] as boolean) ?? false;
        item.favorited = (obj['favorited'] as boolean) ?? false;
        item.status = (obj['status'] as number) ?? 0;
        item.createTime = (obj['createTime'] as string) ?? '';
        this.shares.push(item);
      }
      this.hasMore = arr.length >= PAGE_SIZE;
    }
    this.isLoadingMore = false;
  }

  private onTabChange(index: number): void {
    this.activeTab = index;
    this.refreshList();
  }

  private goToDetail(item: StudyShareItem): void {
    router.pushUrl({
      url: 'pages/StudyShareDetailPage',
      params: { 'id': `${item.id}` } as Record<string, string>
    });
  }

  private goToPublish(): void {
    router.pushUrl({ url: 'pages/StudySharePublishPage' });
  }

  private async toggleLike(item: StudyShareItem): Promise<void> {
    const result = await ApiService.likeStudyShare(item.id);
    if (result.code === 200) {
      this.refreshList();
    }
  }

  private async toggleFavorite(item: StudyShareItem): Promise<void> {
    const result = await ApiService.favoriteStudyShare(item.id);
    if (result.code === 200) {
      this.refreshList();
    }
  }

  private doSearch(): void {
    this.refreshList();
  }

  build() {
    Column() {
      NavHeader({ title: '学习资料' }) {
        Text('上传').fontSize(14).fontColor(Theme.primary).onClick(() => { this.goToPublish() })
      }

      Row() {
        TextInput({ placeholder: '搜索课程名...', text: this.searchInput })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor(Theme.bgInput)
          .borderRadius(18)
          .padding({ left: 16, right: 16 })
          .onChange((val: string) => { this.searchInput = val })
        Text('搜索')
          .fontSize(14)
          .fontColor(Theme.primary)
          .margin({ left: 10 })
          .onClick(() => { this.doSearch() })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })
      .backgroundColor('#FFFFFF')

      Row() {
        Scroll() {
          Row() {
            ForEach(CATEGORY_TABS, (tab: string, index: number) => {
              Column() {
                Text(tab)
                  .fontSize(13)
                  .fontColor(this.activeTab === index ? CATEGORY_COLORS[index] : Theme.textSecondary)
                  .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Regular)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .backgroundColor(this.activeTab === index ? CATEGORY_BG_COLORS[index] : 'transparent')
              }
              .margin({ right: 4 })
              .onClick(() => { this.onTabChange(index) })
            }, (tab: string) => tab)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
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
          ListItem() {
            Row() {
              Text(`共 ${this.shares.length} 项`)
                .fontSize(12).fontColor(Theme.textTertiary)
              Blank()
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 8 })
          }

          if (this.shares.length > 0) {
            ForEach(this.shares, (item: StudyShareItem) => {
              ListItem() {
                ShareCard({
                  itemData: item,
                  onTapCallback: () => this.goToDetail(item),
                  onLikeCallback: () => this.toggleLike(item),
                  onFavoriteCallback: () => this.toggleFavorite(item)
                })
              }
            }, (item: StudyShareItem) => `${item.id}`)

            if (this.hasMore) {
              ListItem() {
                Row() {
                  LoadingProgress().color(Theme.primary).width(20).height(20)
                  Text('加载更多...')
                    .fontSize(13)
                    .fontColor(Theme.textTertiary)
                    .margin({ left: 8 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: 12, bottom: 12 })
              }
            } else {
              ListItem() {
                Text('- 没有更多了 -')
                  .fontSize(13)
                  .fontColor(Theme.textTertiary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 12, bottom: 12 })
              }
            }
          } else {
            ListItem() {
              Column() {
                Text('📚').fontSize(56)
                Text('暂无资料')
                  .fontSize(15).fontColor(Theme.textSecondary).margin({ top: 8 })
                Text('点击右上角"上传"分享学习资料')
                  .fontSize(13).fontColor(Theme.textTertiary).margin({ top: 4 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .margin({ top: 40 })
            }
          }
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .padding({ left: 12, right: 12, top: 4, bottom: 20 })
        .onReachEnd(() => {
          this.loadMore();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
