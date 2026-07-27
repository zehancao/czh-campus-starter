import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const CATEGORIES: string[] = ['表白', '树洞', '吐槽', '交友'];
const CATEGORY_COLORS: string[] = ['#DB2777', Theme.ocean, Theme.primary, '#7C3AED'];

@Entry
@Component
struct ConfessionPublishPage {
  @State private contentInput: string = '';
  @State private selectedCategory: number = 1;
  @State private isAnonymous: number = 0;
  @State private imageUriList: string[] = [];
  @State private imageUrlList: string[] = [];
  @State private isUploading: boolean = false;
  @State private isSubmitting: boolean = false;

  private async pickImagesFromAlbum(): Promise<void> {
    if (this.imageUrlList.length >= 5) {
      AlertDialog.show({
        message: '最多上传5张图片',
        confirm: { value: '知道了', action: () => {} }
      });
      return;
    }
    this.isUploading = true;
    const uris: string[] = await ApiService.pickImages();
    if (uris.length === 0) {
      this.isUploading = false;
      return;
    }
    const maxNew: number = 5 - this.imageUrlList.length;
    const toUpload: string[] = [];
    for (let i = 0; i < Math.min(uris.length, maxNew); i++) {
      toUpload.push(uris[i]);
    }
    for (let i = 0; i < toUpload.length; i++) {
      const url: string = await ApiService.uploadConfessionImage(toUpload[i]);
      if (url.startsWith('ERROR:')) {
        AlertDialog.show({
          message: '图片上传失败，请重试',
          confirm: { value: '确定', action: () => {} }
        });
      } else {
        this.imageUriList.push(toUpload[i]);
        this.imageUrlList.push(url);
      }
    }
    this.isUploading = false;
  }

  private removeImageByIndex(index: number): void {
    const newUris: string[] = [];
    const newUrls: string[] = [];
    for (let i = 0; i < this.imageUriList.length; i++) {
      if (i !== index) {
        newUris.push(this.imageUriList[i]);
        newUrls.push(this.imageUrlList[i]);
      }
    }
    this.imageUriList = newUris;
    this.imageUrlList = newUrls;
  }

  private async submitPublish(): Promise<void> {
    if (this.contentInput.trim().length === 0) {
      AlertDialog.show({
        message: '请输入内容',
        confirm: { value: '好的', action: () => {} }
      });
      return;
    }

    this.isSubmitting = true;
    const imgArr: string[] = [];
    for (let i = 0; i < this.imageUrlList.length; i++) {
      imgArr.push(this.imageUrlList[i]);
    }

    const params: Record<string, Object> = {
      'content': this.contentInput.trim(),
      'category': CATEGORIES[this.selectedCategory],
      'isAnonymous': this.isAnonymous,
      'images': JSON.stringify(imgArr)
    };

    const result = await ApiService.publishConfession(params);
    this.isSubmitting = false;

    if (result.code === 200) {
      promptAction.showToast({ message: '发布成功！' });
      router.back();
    } else {
      AlertDialog.show({
        title: '发布失败',
        message: result.msg || '请稍后重试',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private canSubmit(): boolean {
    return this.contentInput.trim().length > 0 && !this.isSubmitting;
  }

  build() {
    Column() {
      NavHeader({ title: '发布帖子' }) {
        Text(this.isSubmitting ? '发布中…' : '发布')
          .fontSize(14)
          .fontColor(this.canSubmit() ? Theme.primary : Theme.textDisabled)
          .onClick(() => { this.submitPublish() })
      }

      Scroll() {
        Column() {
          Column() {
            Text('分类')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')
              .margin({ bottom: 10 })

            Row() {
              ForEach(CATEGORIES, (cat: string, idx: number) => {
                Text(cat)
                  .fontSize(13)
                  .fontColor(this.selectedCategory === idx ? '#FFFFFF' : CATEGORY_COLORS[idx])
                  .backgroundColor(this.selectedCategory === idx ? CATEGORY_COLORS[idx] : '#FFFFFF')
                  .border({ width: 1, color: CATEGORY_COLORS[idx] })
                  .borderRadius(16)
                  .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                  .margin({ right: 8 })
                  .onClick(() => { this.selectedCategory = idx })
              }, (cat: string) => cat)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(10)

          Column() {
            Text('内容')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')
              .margin({ bottom: 6 })
            TextArea({ placeholder: '说点什么吧...', text: this.contentInput })
              .width('100%')
              .height(150)
              .fontSize(15)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((val: string) => { this.contentInput = val })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(10)

          Column() {
            Row() {
              Text('添加图片')
                .fontSize(14)
                .fontColor(Theme.textPrimary)
              Text(`(${this.imageUrlList.length}/5)`)
                .fontSize(12)
                .fontColor(Theme.textTertiary)
                .margin({ left: 4 })
              Blank()
            }
            .width('100%')
            .margin({ bottom: 8 })

            Scroll() {
              Row() {
                ForEach(this.imageUrlList, (url: string, idx: number) => {
                  Stack() {
                    Image(ApiService.baseUrl + url)
                      .width(76).height(76).borderRadius(8).objectFit(ImageFit.Cover)
                    Text('×')
                      .fontSize(14).fontColor('#FFFFFF')
                      .backgroundColor('#00000080')
                      .width(18).height(18).borderRadius(9)
                      .textAlign(TextAlign.Center)
                      .position({ top: -3, right: -3 })
                      .onClick(() => { this.removeImageByIndex(idx) })
                  }
                  .margin({ right: 8 })
                }, (url: string) => url)

                if (this.imageUrlList.length < 5) {
                  Column() {
                    if (this.isUploading) {
                      LoadingProgress().color(Theme.primary).width(24).height(24)
                    } else {
                      Text('+').fontSize(28).fontColor(Theme.textDisabled)
                      Text('上传').fontSize(10).fontColor(Theme.textDisabled).margin({ top: 2 })
                    }
                  }
                  .width(76).height(76)
                  .backgroundColor(Theme.bgInput)
                  .borderRadius(8)
                  .border({ width: 1, color: Theme.border, style: BorderStyle.Dashed })
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => { this.pickImagesFromAlbum() })
                }
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .width('100%').height(90)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(10)

          Column() {
            Row() {
              Text('匿名发布')
                .fontSize(15)
                .fontColor(Theme.textPrimary)
              Blank()
              Text(this.isAnonymous === 1 ? '🎭 匿名' : '😎 实名')
                .fontSize(13)
                .fontColor(this.isAnonymous === 1 ? Theme.ocean : Theme.textSecondary)
                .onClick(() => {
                  this.isAnonymous = this.isAnonymous === 0 ? 1 : 0;
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#FFFFFF')

          Blank().height(24)

          Button('发布帖子')
            .type(ButtonType.Capsule)
            .width('92%')
            .height(48)
            .backgroundColor(this.canSubmit() ? Theme.primary : Theme.textDisabled)
            .fontColor('#FFFFFF')
            .enabled(this.canSubmit())
            .onClick(() => { this.submitPublish() })
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
