import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const TYPE_OPTIONS: string[] = ['人身安全', '财物丢失', '火情', '医疗', '其他'];
const TYPE_ICONS: Record<string, string> = {
  '人身安全': '🚨',
  '财物丢失': '💰',
  '火情': '🔥',
  '医疗': '🏥',
  '其他': '⚠️'
};

@Entry
@Component
struct SafetyReportPage {
  @State private selectedType: number = 0;
  @State private location: string = '';
  @State private description: string = '';
  @State private imageUris: string[] = [];
  @State private uploadedImages: string[] = [];
  @State private isSubmitting: boolean = false;

  private async doSubmit(): Promise<void> {
    const type: string = TYPE_OPTIONS[this.selectedType];
    if (this.location.length === 0 && this.description.length === 0) {
      this.showToast('请填写位置或情况描述');
      return;
    }

    this.isSubmitting = true;

    for (let i = 0; i < this.imageUris.length; i++) {
      if (this.uploadedImages.length <= i) {
        const url: string = await ApiService.uploadSafetyImage(this.imageUris[i]);
        if (url.startsWith('ERROR')) {
          this.showToast('图片上传失败');
          this.isSubmitting = false;
          return;
        }
        this.uploadedImages.push(url);
      }
    }

    const params: Record<string, Object> = {
      'type': type,
      'location': this.location,
      'description': this.description,
      'images': this.uploadedImages,
    };
    const result = await ApiService.submitSafetyReport(params);
    this.isSubmitting = false;
    if (result.code === 200) {
      this.showToast('求助已提交');
      router.back();
    }
  }

  private async pickImages(): Promise<void> {
    const uris: string[] = await ApiService.pickImages();
    for (let i = 0; i < uris.length; i++) {
      if (this.imageUris.length < 3) {
        this.imageUris.push(uris[i]);
      }
    }
  }

  private removeImage(index: number): void {
    const newUris: string[] = [];
    const newUploaded: string[] = [];
    for (let i = 0; i < this.imageUris.length; i++) {
      if (i !== index) {
        newUris.push(this.imageUris[i]);
        if (i < this.uploadedImages.length) {
          newUploaded.push(this.uploadedImages[i]);
        }
      }
    }
    this.imageUris = newUris;
    this.uploadedImages = newUploaded;
  }

  private showToast(msg: string): void {
    const ctx = this.getUIContext();
    ctx.getPromptAction().showToast({ message: msg, duration: 2000 });
  }

  build() {
    Column() {
      NavHeader({ title: '一键求助' })

      Scroll() {
        Column() {
          Column() {
            Text('⚠️ 紧急类型 *')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')

            Row({ space: 8 }) {
              ForEach(TYPE_OPTIONS, (opt: string, index: number) => {
                Column() {
                  Text(TYPE_ICONS[opt] ?? '⚠️').fontSize(20)
                  Text(opt)
                    .fontSize(11)
                    .fontColor(this.selectedType === index ? Theme.danger : Theme.textSecondary)
                    .margin({ top: 2 })
                }
                .width(58)
                .padding({ top: 8, bottom: 8 })
                .backgroundColor(this.selectedType === index ? '#FEE2E2' : '#F3F4F6')
                .borderRadius(12)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => { this.selectedType = index })
              }, (opt: string) => opt)
            }
            .width('100%')
            .margin({ top: 8 })
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('📍 位置描述')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            TextInput({ placeholder: '如：3号教学楼2层走廊', text: this.location })
              .fontSize(14).width('100%').margin({ top: 4 })
              .onChange((value: string) => { this.location = value })
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('📝 情况描述')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            TextInput({ placeholder: '请简要描述紧急情况...', text: this.description })
              .fontSize(14).width('100%').margin({ top: 4 })
              .onChange((value: string) => { this.description = value })
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('📷 现场图片（可选，最多3张）')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')

            Row({ space: 8 }) {
              ForEach(this.imageUris, (uri: string, index: number) => {
                Stack() {
                  Image(uri)
                    .width(72).height(72).borderRadius(8).objectFit(ImageFit.Cover)
                  Text('×')
                    .fontSize(14).fontColor('#FFFFFF')
                    .width(20).height(20)
                    .borderRadius(10)
                    .backgroundColor('rgba(0,0,0,0.5)')
                    .textAlign(TextAlign.Center)
                    .position({ x: 56, y: 0 })
                    .onClick(() => { this.removeImage(index as number) })
                }
                .width(72).height(72)
              }, (uri: string, index: number) => `${index}`)

              if (this.imageUris.length < 3) {
                Column() {
                  Text('+').fontSize(24).fontColor(Theme.textTertiary)
                  Text('添加图片').fontSize(10).fontColor(Theme.textTertiary)
                }
                .width(72).height(72)
                .backgroundColor('#F3F4F6')
                .borderRadius(8)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => { this.pickImages() })
              }
            }
            .width('100%')
            .margin({ top: 8 })
          }
          .width('100%').margin({ bottom: 20 })

          Button('🚨 提交求助')
            .width('100%').height(48).type(ButtonType.Normal)
            .backgroundColor(Theme.danger).fontColor('#FFFFFF')
            .borderRadius(Theme.radiusMd).fontSize(16).fontWeight(FontWeight.Medium)
            .enabled(!this.isSubmitting)
            .onClick(() => { this.doSubmit() })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%').backgroundColor(Theme.bgPage)
  }
}
