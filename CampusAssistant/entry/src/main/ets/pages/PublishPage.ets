import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { ProductCategory } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';

const CONDITION_OPTIONS: string[] = ['全新', '几乎全新', '轻微使用痕迹', '明显使用痕迹', '成色一般'];
const LOCATION_OPTIONS: string[] = ['一食堂', '二食堂', '图书馆', '宿舍区', '教学楼', '操场', '快递站', '校门口'];

@Entry
@Component
struct PublishPage {
  @State private categories: ProductCategory[] = [];
  @State private selectedCategoryIndex: number = 0;
  @State private selectedConditionIndex: number = 1;
  @State private selectedLocationIndex: number = 0;
  @State private titleInput: string = '';
  @State private descInput: string = '';
  @State private priceInput: string = '';
  @State private originalPriceInput: string = '';
  @State private locationInput: string = '';
  @State private imageUrlList: string[] = [];
  @State private isLoggedIn: boolean = false;
  @State private isLoading: boolean = true;
  @State private isUploading: boolean = false;
  @State private isSubmitting: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    this.loadCategories();
  }

  private async loadCategories(): Promise<void> {
    const result = await ApiService.getProductCategories();
    if (result.code === 200 && result.data !== undefined) {
      this.categories = ApiService.parseProductCategoryList(result.data);
    }
    this.isLoading = false;
  }

  private parseMoney(text: string): number {
    const value: number = Number(text);
    if (isNaN(value)) {
      return -1;
    }
    return value;
  }

  private currentCategoryId(): number {
    if (this.categories.length === 0) {
      return 0;
    }
    const index: number = Math.max(0, Math.min(this.selectedCategoryIndex, this.categories.length - 1));
    return this.categories[index].id;
  }

  private currentLocation(): string {
    if (this.locationInput.trim().length > 0) {
      return this.locationInput.trim();
    }
    const index: number = Math.max(0, Math.min(this.selectedLocationIndex, LOCATION_OPTIONS.length - 1));
    return LOCATION_OPTIONS[index];
  }

  private canSubmitNow(): boolean {
    return this.titleInput.trim().length > 0 &&
      this.descInput.trim().length > 0 &&
      this.priceInput.trim().length > 0 &&
      this.currentCategoryId() > 0 &&
      !this.isSubmitting &&
      !this.isUploading;
  }

  private async pickImagesFromAlbum(): Promise<void> {
    if (this.imageUrlList.length >= 5) {
      AlertDialog.show({ message: '最多上传 5 张图片', confirm: { value: '知道了', action: () => {} } });
      return;
    }
    if (this.isUploading) {
      return;
    }
    this.isUploading = true;
    try {
      promptAction.showToast({ message: '正在打开相册', duration: 1200 });
      const uris: string[] = await ApiService.pickImages();
      const limit: number = Math.min(uris.length, 5 - this.imageUrlList.length);
      for (let i = 0; i < limit; i++) {
        const url: string = await ApiService.uploadImage(uris[i]);
        if (url.startsWith('ERROR:')) {
          AlertDialog.show({ message: '图片上传失败，请重试', confirm: { value: '确定', action: () => {} } });
        } else {
          this.imageUrlList.push(url);
        }
      }
    } catch (err) {
      AlertDialog.show({
        message: '相册无法打开，请用真机或模拟器运行',
        confirm: { value: '知道了', action: () => {} }
      });
    } finally {
      this.isUploading = false;
    }
  }

  private removeImageByIndex(index: number): void {
    const list: string[] = [];
    for (let i = 0; i < this.imageUrlList.length; i++) {
      if (i !== index) {
        list.push(this.imageUrlList[i]);
      }
    }
    this.imageUrlList = list;
  }

  private async submitPublish(): Promise<void> {
    if (!this.isLoggedIn) {
      AlertDialog.show({ message: '请先登录后再发布商品', confirm: { value: '去登录', action: () => { router.pushUrl({ url: 'pages/LoginPage' }) } } });
      return;
    }
    if (!this.canSubmitNow()) {
      AlertDialog.show({ message: '请把分类、标题、价格和描述填写完整', confirm: { value: '好的', action: () => {} } });
      return;
    }
    const price: number = this.parseMoney(this.priceInput.trim());
    const originalPrice: number = this.originalPriceInput.trim().length > 0 ? this.parseMoney(this.originalPriceInput.trim()) : 0;
    if (price <= 0) {
      AlertDialog.show({ message: '售价必须大于 0', confirm: { value: '好的', action: () => {} } });
      return;
    }
    if (originalPrice < 0) {
      AlertDialog.show({ message: '原价格式不正确', confirm: { value: '好的', action: () => {} } });
      return;
    }

    this.isSubmitting = true;
    const params: Record<string, Object> = {
      'categoryId': this.currentCategoryId(),
      'title': this.titleInput.trim(),
      'description': this.descInput.trim(),
      'price': price,
      'originalPrice': originalPrice,
      'conditionLevel': this.selectedConditionIndex + 1,
      'images': this.imageUrlList,
      'campusLocation': this.currentLocation()
    };
    const result = await ApiService.publishProduct(params);
    this.isSubmitting = false;
    if (result.code === 200) {
      promptAction.showToast({ message: '发布成功，等待审核', duration: 1800 });
      router.back();
    } else {
      AlertDialog.show({ title: '发布失败', message: result.msg || '请稍后重试', confirm: { value: '好的', action: () => {} } });
    }
  }

  build() {
    Column() {
      Row() {
        Text('取消').fontSize(16).fontColor(Theme.textSecondary).onClick(() => { router.back() })
        Blank()
        Text('发布商品').fontSize(18).fontWeight(FontWeight.Bold).fontColor(Theme.textPrimary)
        Blank()
        Text(this.isSubmitting ? '提交中' : '发布')
          .fontSize(16)
          .fontColor(this.canSubmitNow() ? Theme.primary : Theme.textTertiary)
          .onClick(() => { this.submitPublish() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(Theme.primary)
          Text('加载发布信息中').fontSize(14).fontColor(Theme.textSecondary).margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (!this.isLoggedIn) {
        Column() {
          Text('请先登录').fontSize(20).fontWeight(FontWeight.Bold).fontColor(Theme.textPrimary)
          Text('登录后才可以发布二手商品').fontSize(14).fontColor(Theme.textSecondary).margin({ top: 8 })
          Button('去登录')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.primary)
            .fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Text('商品图片').fontSize(15).fontWeight(FontWeight.Medium).fontColor(Theme.textPrimary).width('100%')
              Scroll() {
                Row() {
                  ForEach(this.imageUrlList, (url: string, index: number) => {
                    Stack({ alignContent: Alignment.TopEnd }) {
                      Image(ApiService.baseUrl + url)
                        .width(82).height(82).borderRadius(8).objectFit(ImageFit.Cover)
                      Text('×')
                        .width(22).height(22).borderRadius(11)
                        .fontSize(16).fontColor('#FFFFFF').textAlign(TextAlign.Center)
                        .backgroundColor('#00000088')
                        .onClick(() => { this.removeImageByIndex(index) })
                    }.width(82).height(82).margin({ right: 10, top: 10 })
                  }, (url: string) => url)
                  Button() {
                    Column() {
                      Text(this.isUploading ? '上传中' : '+').fontSize(this.isUploading ? 14 : 28).fontColor(Theme.primary)
                      Text(this.imageUrlList.length + '/5').fontSize(12).fontColor(Theme.textSecondary).margin({ top: 2 })
                    }.width(82).height(82).justifyContent(FlexAlign.Center)
                  }
                  .type(ButtonType.Normal)
                  .width(82).height(82)
                  .borderRadius(8)
                  .backgroundColor(Theme.primaryLight)
                  .margin({ top: 10 })
                  .onClick(() => { this.pickImagesFromAlbum() })
                }
              }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF')

            Column() {
              Text('商品分类').fontSize(15).fontWeight(FontWeight.Medium).fontColor(Theme.textPrimary).width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.categories, (item: ProductCategory, index: number) => {
                  Text(item.name)
                    .fontSize(13)
                    .fontColor(this.selectedCategoryIndex === index ? '#FFFFFF' : Theme.textPrimary)
                    .backgroundColor(this.selectedCategoryIndex === index ? Theme.primary : Theme.bgPage)
                    .borderRadius(14)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .margin({ right: 8, top: 10 })
                    .onClick(() => { this.selectedCategoryIndex = index })
                }, (item: ProductCategory) => item.id.toString())
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF').margin({ top: 8 })

            Column() {
              TextInput({ placeholder: '商品标题，例如：二手高数教材', text: this.titleInput })
                .height(46).fontSize(15).backgroundColor(Theme.bgInput).borderRadius(8)
                .onChange((value: string) => { this.titleInput = value })
              Row() {
                TextInput({ placeholder: '售价', text: this.priceInput })
                  .height(46).fontSize(15).backgroundColor(Theme.bgInput).borderRadius(8)
                  .layoutWeight(1).onChange((value: string) => { this.priceInput = value })
                TextInput({ placeholder: '原价，可不填', text: this.originalPriceInput })
                  .height(46).fontSize(15).backgroundColor(Theme.bgInput).borderRadius(8)
                  .layoutWeight(1).margin({ left: 10 }).onChange((value: string) => { this.originalPriceInput = value })
              }.width('100%').margin({ top: 10 })
              TextArea({ placeholder: '描述商品状态、购买时间、配件、交易说明等', text: this.descInput })
                .height(132).fontSize(15).backgroundColor(Theme.bgInput).borderRadius(8)
                .margin({ top: 10 }).onChange((value: string) => { this.descInput = value })
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF').margin({ top: 8 })

            Column() {
              Text('成色').fontSize(15).fontWeight(FontWeight.Medium).fontColor(Theme.textPrimary).width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(CONDITION_OPTIONS, (name: string, index: number) => {
                  Text(name)
                    .fontSize(13)
                    .fontColor(this.selectedConditionIndex === index ? '#FFFFFF' : Theme.textPrimary)
                    .backgroundColor(this.selectedConditionIndex === index ? Theme.success : Theme.bgPage)
                    .borderRadius(14)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .margin({ right: 8, top: 10 })
                    .onClick(() => { this.selectedConditionIndex = index })
                }, (name: string) => name)
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF').margin({ top: 8 })

            Column() {
              Text('交易地点').fontSize(15).fontWeight(FontWeight.Medium).fontColor(Theme.textPrimary).width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(LOCATION_OPTIONS, (name: string, index: number) => {
                  Text(name)
                    .fontSize(13)
                    .fontColor(this.selectedLocationIndex === index && this.locationInput.length === 0 ? '#FFFFFF' : Theme.textPrimary)
                    .backgroundColor(this.selectedLocationIndex === index && this.locationInput.length === 0 ? Theme.primary : Theme.bgPage)
                    .borderRadius(14)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .margin({ right: 8, top: 10 })
                    .onClick(() => {
                      this.selectedLocationIndex = index;
                      this.locationInput = '';
                    })
                }, (name: string) => name)
              }.width('100%')
              TextInput({ placeholder: '也可以手动输入具体地点', text: this.locationInput })
                .height(44).fontSize(14).backgroundColor(Theme.bgInput).borderRadius(8)
                .margin({ top: 12 }).onChange((value: string) => { this.locationInput = value })
            }
            .width('100%').padding(16).backgroundColor('#FFFFFF').margin({ top: 8, bottom: 20 })
          }.width('100%')
        }        .layoutWeight(1).backgroundColor(Theme.bgPage)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
