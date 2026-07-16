
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { LostFoundItem } from '../model/Models';

const CATEGORIES_LIST: string[] = ['电子产品', '证件', '钥匙', '衣物', '其他'];

@Entry
@Component
struct LostFoundPublishPage {
  @State private publishType: number = 1;
  @State private titleInput: string = '';
  @State private descInput: string = '';
  @State private locationInput: string = '';
  @State private selectedCategoryIndex: number = -1;
  @State private phoneInput: string = '';
  @State private imageUriList: string[] = [];
  @State private imageUrlList: string[] = [];
  @State private isUploading: boolean = false;
  @State private isSubmitting: boolean = false;
  @State private creditScore: number = 100;
  @State private canPublish: boolean = true;
  @State private isLoading: boolean = true;
  @State private isLoggedIn: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.checkCredit();
    } else {
      this.isLoading = false;
    }
  }

  private async checkCredit(): Promise<void> {
    const result = await ApiService.getCreditScore();
    if (result.code === 200 && result.data !== undefined) {
      const d: Record<string, Object> = result.data as Record<string, Object>;
      this.creditScore = (d['creditScore'] as number) ?? 100;
      this.canPublish = (d['canTrade'] as boolean) ?? true;
    }
    this.isLoading = false;
  }

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
      const url: string = await ApiService.uploadImage(toUpload[i]);
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
    if (!this.isLoggedIn) {
      AlertDialog.show({
        message: '请先登录',
        confirm: { value: '好的', action: () => {} }
      });
      return;
    }
    if (!this.canPublish) {
      AlertDialog.show({
        message: '信用分 ' + this.creditScore + '，低于85分无法发布',
        confirm: { value: '知道了', action: () => {} }
      });
      return;
    }
    if (this.titleInput.length === 0) {
      AlertDialog.show({
        message: '请输入标题',
        confirm: { value: '好的', action: () => {} }
      });
      return;
    }
    if (this.phoneInput.length === 0) {
      AlertDialog.show({
        message: '请输入联系方式',
        confirm: { value: '好的', action: () => {} }
      });
      return;
    }

    this.isSubmitting = true;

    const lf: LostFoundItem = new LostFoundItem();
    lf.type = this.publishType;
    lf.title = this.titleInput;
    lf.description = this.descInput;
    lf.locationDesc = this.locationInput;
    if (this.selectedCategoryIndex >= 0 && this.selectedCategoryIndex < CATEGORIES_LIST.length) {
      lf.category = CATEGORIES_LIST[this.selectedCategoryIndex];
    } else {
      lf.category = '';
    }
    lf.contactPhone = this.phoneInput;

    const imgArr: string[] = [];
    for (let i = 0; i < this.imageUrlList.length; i++) {
      imgArr.push(this.imageUrlList[i]);
    }
    lf.images = JSON.stringify(imgArr);

    const result = await ApiService.publishLostFound(lf);
    this.isSubmitting = false;

    if (result.code === 200) {
      promptAction.showToast({ message: '发布成功！', duration: 2000 });
      router.back();
    } else {
      AlertDialog.show({
        title: '发布失败',
        message: result.msg || '请稍后重试',
        confirm: { value: '好的', action: () => {} }
      });
    }
  }

  private canSubmitNow(): boolean {
    return this.titleInput.length > 0 && this.phoneInput.length > 0 && !this.isSubmitting;
  }

  build() {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16).fontColor('#6B7280')
          .onClick(() => { router.back() })
        Blank()
        Text('发布信息')
          .fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Text(this.isSubmitting ? '提交中…' : '发布')
          .fontSize(16)
          .fontColor(this.canSubmitNow() ? '#FF6B35' : '#D1D5DB')
          .onClick(() => { this.submitPublish() })
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
      } else if (!this.isLoggedIn) {
        Column() {
          Text('🔒').fontSize(48)
          Text('请先登录再发布信息')
            .fontSize(16).fontColor('#6B7280').margin({ top: 12 })
          Button('去登录')
            .type(ButtonType.Capsule).backgroundColor('#FF6B35').fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.canPublish) {
        Column() {
          Text('😕').fontSize(48)
          Text('信用分不足').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#EF4444')
          Text('当前信用分：' + this.creditScore + '，低于85分无法发布')
            .fontSize(14).fontColor('#6B7280').margin({ top: 8 })
          Button('我知道了')
            .type(ButtonType.Capsule).backgroundColor('#9CA3AF').fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { router.back() })
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Text('发布类型').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#374151')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 10 })

              Row() {
                Button(this.publishType === 1 ? '🔍 寻物' : '寻物')
                  .type(ButtonType.Capsule)
                  .backgroundColor(this.publishType === 1 ? '#FF6B35' : '#F3F4F6')
                  .fontColor(this.publishType === 1 ? '#FFFFFF' : '#6B7280')
                  .height(40).layoutWeight(1).margin({ right: 8 })
                  .onClick(() => { this.publishType = 1 })
                Button(this.publishType === 2 ? '📢 招领' : '招领')
                  .type(ButtonType.Capsule)
                  .backgroundColor(this.publishType === 2 ? '#10B981' : '#F3F4F6')
                  .fontColor(this.publishType === 2 ? '#FFFFFF' : '#6B7280')
                  .height(40).layoutWeight(1)
                  .onClick(() => { this.publishType = 2 })
              }
              .width('100%')

              Column() {
                Row() {
                  Text('添加图片').fontSize(14).fontColor('#374151')
                  Text('(' + this.imageUrlList.length + '/5)').fontSize(12).fontColor('#9CA3AF').margin({ left: 4 })
                  Blank()
                }
                .width('100%')
                .margin({ top: 14, bottom: 8 })

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
                          LoadingProgress().color('#FF6B35').width(24).height(24)
                        } else {
                          Text('+').fontSize(28).fontColor('#D1D5DB')
                          Text('上传').fontSize(10).fontColor('#D1D5DB').margin({ top: 2 })
                        }
                      }
                      .width(76).height(76)
                      .backgroundColor('#F9FAFB')
                      .borderRadius(8)
                      .border({ width: 1, color: '#E5E7EB', style: BorderStyle.Dashed })
                      .justifyContent(FlexAlign.Center)
                      .onClick(() => { this.pickImagesFromAlbum() })
                    }
                  }
                }
                .scrollable(ScrollDirection.Horizontal)
                .width('100%').height(90)
              }
              .width('100%')
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .padding(16)

            Blank().height(10)


            Column() {
              Row() {
                Text('标题').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#374151')
                Text(' *').fontSize(15).fontColor('#EF4444')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })
              TextInput({ placeholder: '如：丢失校园卡、捡到钥匙串', text: this.titleInput })
                .width('100%').height(46).fontSize(15)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((val: string) => { this.titleInput = val })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .padding(16)

            Blank().height(10)

            Column() {
              Row() {
                Text('详细描述').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#374151')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })
              TextArea({ placeholder: '描述物品特征、丢失/拾到时间、周围环境等…', text: this.descInput })
                .width('100%').height(120).fontSize(15)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((val: string) => { this.descInput = val })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .padding(16)

            Blank().height(10)

            Column() {
              Row() {
                Text('地点').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#374151')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })
              TextInput({ placeholder: '如：二教203、一食堂二楼', text: this.locationInput })
                .width('100%').height(46).fontSize(15)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((val: string) => { this.locationInput = val })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .padding(16)

            Blank().height(10)

            Column() {
              Row() {
                Text('联系方式').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#374151')
                Text(' *').fontSize(15).fontColor('#EF4444')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })
              TextInput({ placeholder: '手机号', text: this.phoneInput })
                .width('100%').height(46).fontSize(15)
                .type(InputType.Number)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((val: string) => { this.phoneInput = val })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .padding(16)

            Blank().height(10)

            Column() {
              Row() {
                Text('物品分类').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#374151')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 10 })

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(CATEGORIES_LIST, (cat: string, idx: number) => {
                  Text(cat)
                    .fontSize(13)
                    .fontColor(this.selectedCategoryIndex === idx ? '#FF6B35' : '#6B7280')
                    .backgroundColor(this.selectedCategoryIndex === idx ? '#FFF3ED' : '#F3F4F6')
                    .border({ width: 1, color: this.selectedCategoryIndex === idx ? '#FF6B35' : '#E5E7EB' })
                    .borderRadius(16)
                    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                    .margin({ right: 10, bottom: 10 })
                    .onClick(() => { this.selectedCategoryIndex = idx })
                }, (cat: string) => cat)
              }
              .width('100%')
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .padding(16)

            Blank().height(10)

            Row() {
              Text('💳').fontSize(16)
              Text('当前信用分：' + this.creditScore + '  |  发布需 ≥85分')
                .fontSize(13).fontColor(this.canPublish ? '#10B981' : '#EF4444')
                .margin({ left: 6 })
              Blank()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('#FFFFFF')

            Blank().height(16)
            Button(this.isSubmitting ? '发布中…' : '提交' + (this.publishType === 1 ? '寻物' : '招领') + '信息')
              .type(ButtonType.Capsule)
              .width('92%')
              .height(48)
              .backgroundColor(this.canSubmitNow() ? (this.publishType === 1 ? '#FF6B35' : '#10B981') : '#D1D5DB')
              .fontColor('#FFFFFF')
              .margin({ bottom: 40 })
              .enabled(this.canSubmitNow())
              .onClick(() => { this.submitPublish() })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F2F5')
  }
}
