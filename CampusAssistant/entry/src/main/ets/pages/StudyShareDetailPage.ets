import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { filePreview } from '@kit.PreviewKit';
import { http } from '@kit.NetworkKit';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { StudyShareItem } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const PREVIEWABLE_TYPES: string[] = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'gif', 'webp'];
const MIME_MAP: Record<string, string> = {
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp'
};

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

const CATEGORY_COLORS: Record<string, string> = {
  '课件': '#0288D1',
  '笔记': Theme.ocean,
  '真题': '#D97706',
  '作业': Theme.success,
  '其他': Theme.textSecondary
};
const CATEGORY_BG: Record<string, string> = {
  '课件': '#E0F0FF',
  '笔记': Theme.oceanLight,
  '真题': '#FFF9E6',
  '作业': Theme.successLight,
  '其他': '#F3F4F6'
};

@Entry
@Component
struct StudyShareDetailPage {
  @State private share: StudyShareItem = new StudyShareItem();
  @State private isLoading: boolean = true;
  @State private errorMsg: string = '';
  @State private isMyShare: boolean = false;

  private shareId: number = 0;

  aboutToAppear(): void {
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params !== undefined && params !== null) {
      const idObj: Object = params['id'];
      if (idObj !== undefined && idObj !== null) {
        this.shareId = parseInt(idObj as string, 10);
      }
    }
    if (this.shareId > 0) {
      this.loadDetail();
    } else {
      this.errorMsg = '参数错误';
      this.isLoading = false;
    }
  }

  private async loadDetail(): Promise<void> {
    this.isLoading = true;
    const result = await ApiService.getStudyShareDetail(this.shareId);
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      this.share.id = (obj['id'] as number) ?? 0;
      this.share.userId = (obj['userId'] as number) ?? 0;
      this.share.uploaderName = (obj['uploaderName'] as string) ?? '';
      this.share.uploaderAvatar = (obj['uploaderAvatar'] as string) ?? '';
      this.share.title = (obj['title'] as string) ?? '';
      this.share.description = (obj['description'] as string) ?? '';
      this.share.courseName = (obj['courseName'] as string) ?? '';
      this.share.category = (obj['category'] as string) ?? '其他';
      this.share.fileUrl = (obj['fileUrl'] as string) ?? '';
      this.share.fileType = (obj['fileType'] as string) ?? '';
      this.share.fileSize = (obj['fileSize'] as number) ?? 0;
      this.share.coverImage = (obj['coverImage'] as string) ?? '';
      this.share.likeCount = (obj['likeCount'] as number) ?? 0;
      this.share.favoriteCount = (obj['favoriteCount'] as number) ?? 0;
      this.share.downloadCount = (obj['downloadCount'] as number) ?? 0;
      this.share.liked = (obj['liked'] as boolean) ?? false;
      this.share.favorited = (obj['favorited'] as boolean) ?? false;
      this.share.status = (obj['status'] as number) ?? 0;
      this.share.createTime = (obj['createTime'] as string) ?? '';

      const store: AppStore = AppStore.getInstance();
      if (store.isLoggedIn && store.userInfo.id === this.share.userId) {
        this.isMyShare = true;
      }
    } else {
      this.errorMsg = '加载失败';
    }
    this.isLoading = false;
  }

  private async toggleLike(): Promise<void> {
    const result = await ApiService.likeStudyShare(this.shareId);
    if (result.code === 200) {
      this.loadDetail();
    }
  }

  private async toggleFavorite(): Promise<void> {
    const result = await ApiService.favoriteStudyShare(this.shareId);
    if (result.code === 200) {
      this.loadDetail();
    }
  }

  private async doDownload(): Promise<void> {
    const result = await ApiService.downloadStudyShare(this.shareId);
    if (result.code === 200) {
      this.share.downloadCount = this.share.downloadCount + 1;
    }
    const store: AppStore = AppStore.getInstance();
    if (store.context === undefined) {
      promptAction.showToast({ message: '下载失败' });
      return;
    }
    const downloadDir: string = store.context.filesDir;
    const ext: string = this.share.fileType.length > 0 ? this.share.fileType : 'pdf';
    const fileName: string = `${this.share.title.replace(new RegExp('[\\\\/:*?\"<>|]', 'g'), '_')}.${ext}`;
    const destPath: string = `${downloadDir}/${fileName}`;
    const remoteUrl: string = `${ApiService.baseUrl}${this.share.fileUrl}`;
    const req: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await req.request(remoteUrl, {
        method: http.RequestMethod.GET,
        header: { 'Authorization': `Bearer ${store.token}` }
      });
      if (response.responseCode === 200) {
        const resultData: ArrayBuffer = response.result as ArrayBuffer;
        const file: fileIo.File = fileIo.openSync(destPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        fileIo.writeSync(file.fd, resultData);
        fileIo.closeSync(file);
        promptAction.showToast({ message: `已保存到 ${destPath}` });
      } else {
        promptAction.showToast({ message: '下载失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '下载失败' });
    } finally {
      req.destroy();
    }
  }

  private isPreviewable(): boolean {
    const ext: string = this.share.fileType.toLowerCase();
    for (let i = 0; i < PREVIEWABLE_TYPES.length; i++) {
      if (PREVIEWABLE_TYPES[i] === ext) return true;
    }
    return false;
  }

  private async doPreview(): Promise<void> {
    const ext: string = this.share.fileType.toLowerCase();
    if (!this.isPreviewable()) {
      promptAction.showToast({ message: '该格式不支持预览' });
      return;
    }

    const store: AppStore = AppStore.getInstance();
    if (store.context === undefined) {
      promptAction.showToast({ message: '预览失败' });
      return;
    }

    const cacheDir: string = store.context.cacheDir;
    const fileName: string = `preview_${this.shareId}.${ext}`;
    const localPath: string = `${cacheDir}/${fileName}`;

    try {
      if (fileIo.accessSync(localPath)) {
        fileIo.unlinkSync(localPath);
      }
    } catch (e) {
    }

    const remoteUrl: string = `${ApiService.baseUrl}${this.share.fileUrl}`;
    const req: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await req.request(remoteUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        header: {}
      });
      if (response.responseCode === 200) {
        const resultData: ArrayBuffer = response.result as ArrayBuffer;
        const file: fileIo.File = fileIo.openSync(localPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        fileIo.writeSync(file.fd, resultData);
        fileIo.closeSync(file);
      } else {
        promptAction.showToast({ message: '下载文件失败' });
        return;
      }
    } catch (e) {
      promptAction.showToast({ message: '下载文件失败' });
      return;
    } finally {
      req.destroy();
    }

    if (ext === 'pdf') {
      router.pushUrl({
        url: 'pages/StudySharePreviewPage',
        params: {
          'shareId': `${this.shareId}`,
          'fileUrl': this.share.fileUrl,
          'title': this.share.title
        } as Record<string, string>
      });
    } else {
      const uri: fileUri.FileUri = new fileUri.FileUri(localPath);
      const mime: string | undefined = MIME_MAP[ext];
      const mimeType: string = mime !== undefined ? mime : 'application/octet-stream';
      const fileInfo: filePreview.PreviewInfo = {
        title: this.share.title,
        uri: uri.toString(),
        mimeType: mimeType
      };
      try {
        filePreview.openPreview(store.context, fileInfo);
      } catch (e) {
        promptAction.showToast({ message: '预览失败，请下载后查看' });
      }
    }
  }

  private doReport(): void {
    AlertDialog.show({
      title: '举报',
      message: '确定要举报这份资料吗？',
      primaryButton: { value: '取消', action: () => {} },
      confirm: {
        value: '举报',
        fontColor: Theme.danger,
        action: () => { this.submitReport(); }
      }
    });
  }

  private async submitReport(): Promise<void> {
    const result = await ApiService.reportStudyShare(this.shareId);
    if (result.code === 200) {
      promptAction.showToast({ message: '已举报' });
      router.back();
    }
  }

  private deleteShare(): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这份资料吗？',
      primaryButton: { value: '取消', action: () => {} },
      confirm: {
        value: '删除',
        fontColor: Theme.danger,
        action: () => { this.doDelete(); }
      }
    });
  }

  private async doDelete(): Promise<void> {
    const result = await ApiService.deleteStudyShare(this.shareId);
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

  private formatFileSize(bytes: number): string {
    if (bytes <= 0) return '';
    if (bytes < 1024) return `${bytes}B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
  }

  private getFileIcon(): string {
    const icon: string | undefined = FILE_TYPE_ICONS[this.share.fileType.toLowerCase()];
    return icon !== undefined ? icon : '📁';
  }

  private getCategoryColor(): string {
    const c: string | undefined = CATEGORY_COLORS[this.share.category];
    return c !== undefined ? c : Theme.textSecondary;
  }

  private getCategoryBg(): string {
    const b: string | undefined = CATEGORY_BG[this.share.category];
    return b !== undefined ? b : '#F3F4F6';
  }

  build() {
    Column() {
      NavHeader({ title: '资料详情' }) {
        if (this.isMyShare && !this.isLoading) {
          Text('删除').fontSize(14).fontColor(Theme.danger).onClick(() => { this.deleteShare() })
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
                Text(this.share.uploaderName)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.textPrimary)
                Text(this.formatTime(this.share.createTime))
                  .fontSize(12)
                  .fontColor(Theme.textTertiary)
                  .margin({ left: 10 })
                Blank()
                Text(this.share.category)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.getCategoryColor())
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(10)
                  .backgroundColor(this.getCategoryBg())
              }
              .width('100%')

              Text(this.share.title)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
                .width('100%')
                .margin({ top: 12 })
                .lineHeight(26)

              if (this.share.courseName.length > 0) {
                Row() {
                  Text('📚')
                    .fontSize(14)
                  Text(this.share.courseName)
                    .fontSize(14)
                    .fontColor(Theme.ocean)
                    .margin({ left: 4 })
                }
                .margin({ top: 8 })
              }

              Stack() {
                if (this.share.coverImage.length > 0) {
                  Image(`${ApiService.baseUrl}${this.share.coverImage}`)
                    .width('100%')
                    .height(200)
                    .borderRadius(Theme.radiusMd)
                    .objectFit(ImageFit.Cover)
                } else {
                  Column() {
                    Text(this.getFileIcon())
                      .fontSize(40)
                    Text(this.share.fileType.toUpperCase())
                      .fontSize(14)
                      .fontColor(Theme.textSecondary)
                      .margin({ top: 4 })
                  }
                  .width('100%')
                  .height(120)
                  .backgroundColor(Theme.bgInput)
                  .borderRadius(Theme.radiusMd)
                  .justifyContent(FlexAlign.Center)
                }
                Row() {
                  Text(this.getFileIcon())
                    .fontSize(12)
                  Text(this.share.fileType.toUpperCase())
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .margin({ left: 2 })
                }
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(4)
                .backgroundColor('#00000080')
                .position({ bottom: 8, right: 8 })
              }
              .width('100%')
              .margin({ top: 12 })

              if (this.share.description.length > 0) {
                Text(this.share.description)
                  .fontSize(14)
                  .fontColor(Theme.textSecondary)
                  .width('100%')
                  .margin({ top: 12 })
                  .lineHeight(22)
              }

              Row() {
                Text(this.formatFileSize(this.share.fileSize))
                  .fontSize(12)
                  .fontColor(Theme.textTertiary)
                Text('·')
                  .fontSize(12)
                  .fontColor(Theme.textTertiary)
                  .margin({ left: 6, right: 6 })
                Text(`${this.share.downloadCount}次下载`)
                  .fontSize(12)
                  .fontColor(Theme.textTertiary)
              }
              .margin({ top: 10 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(Theme.cardRadius)

            Blank().height(10)

            Row() {
              Row() {
                Text(this.share.liked ? '❤️' : '🤍').fontSize(20)
                Text(`${this.share.likeCount}`)
                  .fontSize(14)
                  .fontColor(this.share.liked ? Theme.danger : Theme.textTertiary)
                  .margin({ left: 6 })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .height(48)
              .backgroundColor('#FFFFFF')
              .borderRadius(Theme.cardRadius)
              .onClick(() => { this.toggleLike() })

              Row() {
                Text(this.share.favorited ? '⭐' : '☆').fontSize(20)
                Text(`${this.share.favoriteCount}`)
                  .fontSize(14)
                  .fontColor(this.share.favorited ? '#D97706' : Theme.textTertiary)
                  .margin({ left: 6 })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .height(48)
              .backgroundColor('#FFFFFF')
              .borderRadius(Theme.cardRadius)
              .margin({ left: 6 })
              .onClick(() => { this.toggleFavorite() })

              Column() {
                Text('👁️').fontSize(20)
                Text('预览')
                  .fontSize(14)
                  .fontColor(this.isPreviewable() ? Theme.ocean : Theme.textDisabled)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .height(48)
              .backgroundColor('#FFFFFF')
              .borderRadius(Theme.cardRadius)
              .margin({ left: 6 })
              .enabled(this.isPreviewable())
              .onClick(() => { this.doPreview() })

              Column() {
                Text('📥').fontSize(20)
                Text('下载')
                  .fontSize(14)
                  .fontColor(Theme.primary)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .height(48)
              .backgroundColor('#FFFFFF')
              .borderRadius(Theme.cardRadius)
              .margin({ left: 6 })
              .onClick(() => { this.doDownload() })
            }
            .width('100%')
            .margin({ top: 2 })

            if (!this.isMyShare) {
              Text('举报此资料')
                .fontSize(13)
                .fontColor(Theme.textTertiary)
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ top: 16 })
                .onClick(() => { this.doReport() })
            }
          }
          .padding({ left: 12, right: 12, top: 8, bottom: 20 })
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
