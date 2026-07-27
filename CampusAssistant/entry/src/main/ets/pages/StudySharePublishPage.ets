import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import common from '@ohos.app.ability.common';
import { ApiService } from '../service/ApiService';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const CATEGORIES: string[] = ['课件', '笔记', '真题', '作业', '其他'];
const CATEGORY_COLORS: string[] = ['#0288D1', Theme.ocean, '#D97706', Theme.success, Theme.textSecondary];

@Entry
@Component
struct StudySharePublishPage {
  @State private titleInput: string = '';
  @State private descriptionInput: string = '';
  @State private courseNameInput: string = '';
  @State private selectedCategory: number = 0;
  @State private fileUri: string = '';
  @State private fileUrl: string = '';
  @State private fileTypeName: string = '';
  @State private coverUri: string = '';
  @State private coverUrl: string = '';
  @State private isUploading: boolean = false;
  @State private isUploadingCover: boolean = false;
  @State private isSubmitting: boolean = false;

  private async pickFile(): Promise<void> {
    this.isUploading = true;
    try {
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const documentViewPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const uris: string[] = await documentViewPicker.select(documentSelectOptions);
      if (uris.length > 0) {
        this.fileUri = uris[0];
        const url: string = await ApiService.uploadStudyShareFile(this.fileUri);
        if (url.startsWith('ERROR:')) {
          AlertDialog.show({
            message: `文件上传失败：${url}`,
            confirm: { value: '确定', action: () => {} }
          });
        } else {
          this.fileUrl = url;
          const ext: string = this.getExtensionFromUri(this.fileUri);
          this.fileTypeName = ext;
        }
      }
    } catch (e) {
      const errMsg: string = e !== null && e !== undefined && typeof e === 'object' ? String(e) : '未知错误';
      AlertDialog.show({
        message: `选择文件失败：${errMsg}`,
        confirm: { value: '确定', action: () => {} }
      });
    }
    this.isUploading = false;
  }

  private async pickCoverImage(): Promise<void> {
    this.isUploadingCover = true;
    const uris: string[] = await ApiService.pickImages();
    if (uris.length > 0) {
      const url: string = await ApiService.uploadStudyShareCover(uris[0]);
      if (url.startsWith('ERROR:')) {
        AlertDialog.show({
          message: '封面上传失败，请重试',
          confirm: { value: '确定', action: () => {} }
        });
      } else {
        this.coverUri = uris[0];
        this.coverUrl = url;
      }
    }
    this.isUploadingCover = false;
  }

  private removeCover(): void {
    this.coverUri = '';
    this.coverUrl = '';
  }

  private removeFile(): void {
    this.fileUri = '';
    this.fileUrl = '';
    this.fileTypeName = '';
  }

  private getExtensionFromUri(uri: string): string {
    const parts: string[] = uri.split('.');
    if (parts.length > 1) {
      const ext: string = parts[parts.length - 1].toLowerCase();
      if (ext.length <= 5) return ext;
    }
    return 'file';
  }

  private async submitPublish(): Promise<void> {
    if (this.titleInput.trim().length === 0) {
      AlertDialog.show({
        message: '请输入资料标题',
        confirm: { value: '好的', action: () => {} }
      });
      return;
    }
    if (this.fileUrl.length === 0) {
      AlertDialog.show({
        message: '请上传资料文件',
        confirm: { value: '好的', action: () => {} }
      });
      return;
    }

    this.isSubmitting = true;
    const params: Record<string, Object> = {
      'title': this.titleInput.trim(),
      'description': this.descriptionInput.trim(),
      'courseName': this.courseNameInput.trim(),
      'category': CATEGORIES[this.selectedCategory],
      'fileUrl': this.fileUrl,
      'fileType': this.fileTypeName,
      'coverImage': this.coverUrl
    };

    const result = await ApiService.publishStudyShare(params);
    this.isSubmitting = false;

    if (result.code === 200) {
      promptAction.showToast({ message: '上传成功！' });
      router.back();
    } else {
      AlertDialog.show({
        title: '上传失败',
        message: result.msg !== undefined && result.msg !== null ? result.msg as string : '请稍后重试',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private canSubmit(): boolean {
    return this.titleInput.trim().length > 0 && this.fileUrl.length > 0 && !this.isSubmitting;
  }

  build() {
    Column() {
      NavHeader({ title: '上传资料' }) {
        Text(this.isSubmitting ? '上传中…' : '上传')
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
            Text('标题')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')
              .margin({ bottom: 6 })
            TextInput({ placeholder: '输入资料标题', text: this.titleInput })
              .width('100%')
              .height(Theme.inputHeight)
              .fontSize(15)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((val: string) => { this.titleInput = val })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(10)

          Column() {
            Text('关联课程（可选）')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')
              .margin({ bottom: 6 })
            TextInput({ placeholder: '如：高等数学', text: this.courseNameInput })
              .width('100%')
              .height(Theme.inputHeight)
              .fontSize(15)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((val: string) => { this.courseNameInput = val })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(10)

          Column() {
            Text('描述（可选）')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')
              .margin({ bottom: 6 })
            TextArea({ placeholder: '补充资料说明...', text: this.descriptionInput })
              .width('100%')
              .height(100)
              .fontSize(15)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((val: string) => { this.descriptionInput = val })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(10)

          Column() {
            Row() {
              Text('上传文件')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
              Text('（必填）')
                .fontSize(12)
                .fontColor(Theme.danger)
                .margin({ left: 4 })
              Blank()
            }
            .width('100%')
            .margin({ bottom: 4 })

            Text('支持 PDF / Word / PPT / Excel / 图片 / 压缩包')
              .fontSize(12)
              .fontColor(Theme.textTertiary)
              .width('100%')
              .margin({ bottom: 8 })

            if (this.fileUrl.length > 0) {
              Row() {
                Text('📄')
                  .fontSize(20)
                Text(this.fileTypeName.length > 0 ? this.fileTypeName.toUpperCase() : '文件')
                  .fontSize(14)
                  .fontColor(Theme.textPrimary)
                  .margin({ left: 8 })
                  .layoutWeight(1)
                Text('×')
                  .fontSize(16)
                  .fontColor(Theme.textTertiary)
                  .onClick(() => { this.removeFile() })
              }
              .width('100%')
              .height(48)
              .padding({ left: 12, right: 12 })
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .alignItems(VerticalAlign.Center)
            } else {
              Column() {
                if (this.isUploading) {
                  LoadingProgress().color(Theme.primary).width(24).height(24)
                  Text('上传中...').fontSize(12).fontColor(Theme.textTertiary).margin({ top: 4 })
                } else {
                  Text('+').fontSize(28).fontColor(Theme.textDisabled)
                  Text('选择文件').fontSize(12).fontColor(Theme.textDisabled).margin({ top: 2 })
                }
              }
              .width('100%')
              .height(80)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .border({ width: 1, color: Theme.border, style: BorderStyle.Dashed })
              .justifyContent(FlexAlign.Center)
              .onClick(() => { this.pickFile() })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(10)

          Column() {
            Row() {
              Text('封面图（可选）')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
              Blank()
            }
            .width('100%')
            .margin({ bottom: 8 })

            if (this.coverUrl.length > 0) {
              Stack() {
                Image(ApiService.baseUrl + this.coverUrl)
                  .width(76).height(76).borderRadius(8).objectFit(ImageFit.Cover)
                Text('×')
                  .fontSize(14).fontColor('#FFFFFF')
                  .backgroundColor('#00000080')
                  .width(18).height(18).borderRadius(9)
                  .textAlign(TextAlign.Center)
                  .position({ top: -3, right: -3 })
                  .onClick(() => { this.removeCover() })
              }
            } else {
              Column() {
                if (this.isUploadingCover) {
                  LoadingProgress().color(Theme.primary).width(24).height(24)
                } else {
                  Text('+').fontSize(28).fontColor(Theme.textDisabled)
                  Text('上传封面').fontSize(10).fontColor(Theme.textDisabled).margin({ top: 2 })
                }
              }
              .width(76)
              .height(76)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .border({ width: 1, color: Theme.border, style: BorderStyle.Dashed })
              .justifyContent(FlexAlign.Center)
              .onClick(() => { this.pickCoverImage() })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Blank().height(24)

          Button('上传资料')
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
