import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { pdfService, PdfView, pdfViewManager } from '@kit.PDFKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { AppStore } from '../service/AppStore';
import { ApiService } from '../service/ApiService';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

@Entry
@Component
struct StudySharePreviewPage {
  @State private loadResult: pdfService.ParseResult = pdfService.ParseResult.PARSE_ERROR_FORMAT;
  @State private isLoading: boolean = true;
  @State private errorMsg: string = '';
  @State private currentPage: number = 0;
  @State private totalPages: number = 0;

  private controller: pdfViewManager.PdfController = new pdfViewManager.PdfController();
  private localPath: string = '';
  private shareId: number = 0;
  private fileUrl: string = '';
  private title: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params !== undefined && params !== null) {
      const idObj: Object = params['shareId'];
      if (idObj !== undefined && idObj !== null) {
        this.shareId = parseInt(idObj as string, 10);
      }
      const urlObj: Object = params['fileUrl'];
      if (urlObj !== undefined && urlObj !== null) {
        this.fileUrl = urlObj as string;
      }
      const titleObj: Object = params['title'];
      if (titleObj !== undefined && titleObj !== null) {
        this.title = titleObj as string;
      }
    }
    this.downloadAndLoad();
  }

  aboutToDisappear(): void {
  }

  private async downloadAndLoad(): Promise<void> {
    this.isLoading = true;
    const store: AppStore = AppStore.getInstance();
    if (store.context === undefined) {
      this.errorMsg = '上下文错误';
      this.isLoading = false;
      return;
    }

    const cacheDir: string = store.context.cacheDir;
    const fileName: string = `preview_${this.shareId}.pdf`;
    this.localPath = `${cacheDir}/${fileName}`;

    try {
      if (fileIo.accessSync(this.localPath)) {
        fileIo.unlinkSync(this.localPath);
      }
    } catch (e) {
    }

    const remoteUrl: string = `${ApiService.baseUrl}${this.fileUrl}`;
    const req: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await req.request(remoteUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        header: {}
      });

      if (response.responseCode === 200) {
        const resultData: ArrayBuffer = response.result as ArrayBuffer;
        const file: fileIo.File = fileIo.openSync(this.localPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        fileIo.writeSync(file.fd, resultData);
        fileIo.closeSync(file);

        try {
          this.loadResult = await this.controller.loadDocument(this.localPath);
        } catch (e) {
          this.loadResult = pdfService.ParseResult.PARSE_ERROR_FORMAT;
        }
        if (this.loadResult === pdfService.ParseResult.PARSE_SUCCESS) {
          this.controller.registerPageCountChangedListener((count: number) => {
            this.totalPages = count;
          });
          this.controller.registerPageChangedListener((page: number) => {
            this.currentPage = page;
          });
        } else {
          this.errorMsg = `PDF解析失败(code=${this.loadResult})`;
        }
      } else {
        this.errorMsg = `下载失败(code=${response.responseCode})`;
      }
    } catch (e) {
      this.errorMsg = '加载失败';
    } finally {
      req.destroy();
    }
    this.isLoading = false;
  }

  private prevPage(): void {
    if (this.currentPage > 0) {
      this.controller.goToPage(this.currentPage - 1);
    }
  }

  private nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.controller.goToPage(this.currentPage + 1);
    }
  }

  build() {
    Column() {
      NavHeader({ title: this.title.length > 0 ? this.title : 'PDF预览' })

      if (this.isLoading) {
        Column() {
          LoadingProgress().color(Theme.primary).width(40).height(40)
          Text('正在加载PDF...')
            .fontSize(14)
            .fontColor(Theme.textSecondary)
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMsg.length > 0) {
        Column() {
          Text('😕').fontSize(48)
          Text(this.errorMsg).fontSize(16).fontColor(Theme.textSecondary).margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        PdfView({
          controller: this.controller,
          pageFit: pdfService.PageFit.FIT_WIDTH,
          showScroll: true
        })
          .layoutWeight(1)

        Row() {
          Button('上一页')
            .type(ButtonType.Capsule)
            .height(36)
            .fontSize(13)
            .backgroundColor(this.currentPage > 0 ? Theme.primary : Theme.textDisabled)
            .fontColor('#FFFFFF')
            .enabled(this.currentPage > 0)
            .onClick(() => { this.prevPage() })

          Text(`${this.currentPage + 1} / ${this.totalPages}`)
            .fontSize(14)
            .fontColor(Theme.textPrimary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Button('下一页')
            .type(ButtonType.Capsule)
            .height(36)
            .fontSize(13)
            .backgroundColor(this.currentPage < this.totalPages - 1 ? Theme.primary : Theme.textDisabled)
            .fontColor('#FFFFFF')
            .enabled(this.currentPage < this.totalPages - 1)
            .onClick(() => { this.nextPage() })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .border({ width: { top: 0.5 }, color: Theme.border })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
