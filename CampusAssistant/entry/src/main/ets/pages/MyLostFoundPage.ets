
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { LostFoundItem } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const STATUS_OPTIONS: string[] = ['进行中', '已找到/已归还'];
const STATUS_COLORS: string[] = [Theme.warning, Theme.success];

@Component
struct MyLFItemCard {
  private itemData: LostFoundItem = new LostFoundItem();
  private onTapCallback?: () => void;
  private onMarkDone?: (item: LostFoundItem) => void;
  private onDelete?: (item: LostFoundItem) => void;

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.itemData.type === 1 ? '🔍' : '📢')
            .fontSize(28)
          Text(this.itemData.type === 1 ? '寻物' : '招领')
            .fontSize(11).fontColor(Theme.secondary).margin({ top: 2 })
        }
        .width(56).height(56)
        .backgroundColor(Theme.secondaryLight)
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)

        Column() {
          Row() {
            Text(this.itemData.title)
              .fontSize(15).fontWeight(FontWeight.Medium)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(STATUS_OPTIONS[Math.max(0, Math.min(this.itemData.status - 1, 1))])
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(STATUS_COLORS[Math.max(0, Math.min(this.itemData.status - 1, 1))])
              .borderRadius(4)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          }
          .width('100%')

          if (this.itemData.description.length > 0) {
            Text(this.itemData.description)
              .fontSize(13).fontColor(Theme.textSecondary)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 4 })
          }

          Row() {
            if (this.itemData.category.length > 0) {
              Text(this.itemData.category)
                .fontSize(11).fontColor(Theme.textTertiary).backgroundColor(Theme.bgPage)
                .borderRadius(4).padding({ left: 6, right: 6, top: 1, bottom: 1 })
            }
            if (this.itemData.locationDesc.length > 0) {
              Text(this.itemData.locationDesc)
                .fontSize(11).fontColor(Theme.textTertiary)
                .margin({ left: 6 })
            }
            Blank()
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Divider().height(1).color(Theme.divider).width('100%').margin({ top: 8, bottom: 8 })

      Row() {
        Text(this.itemData.createTime.replace('T', ' ').substring(0, 16))
          .fontSize(11).fontColor(Theme.textTertiary)

        Blank()

        Button('标记已找到')
          .type(ButtonType.Capsule)
          .fontSize(12).fontColor(Theme.success)
          .backgroundColor(Theme.successLight)
          .height(28)
          .margin({ right: 8 })
          .onClick(() => {
            if (this.onMarkDone !== undefined) {
              this.onMarkDone(this.itemData);
            }
          })

        Button('删除')
          .type(ButtonType.Capsule)
          .fontSize(12).fontColor(Theme.danger)
          .backgroundColor(Theme.dangerLight)
          .height(28)
          .onClick(() => {
            if (this.onDelete !== undefined) {
              this.onDelete(this.itemData);
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      if (this.onTapCallback !== undefined) {
        this.onTapCallback();
      }
    })
  }
}

@Entry
@Component
struct MyLostFoundPage {
  @State private items: LostFoundItem[] = [];
  @State private isLoading: boolean = true;
  @State private isLoggedIn: boolean = false;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.loadList();
    } else {
      this.isLoading = false;
    }
  }

  onPageShow(): void {
    const store: AppStore = AppStore.getInstance();
    if (store.isLoggedIn) {
      this.loadList();
    }
  }

  private async loadList(): Promise<void> {
    this.isLoading = true;
    const result = await ApiService.getMyLostFoundList();
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const list: LostFoundItem[] = [];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        const item: LostFoundItem = new LostFoundItem();
        item.id = (obj['id'] as number) ?? 0;
        item.userId = (obj['userId'] as number) ?? 0;
        item.userName = (obj['userName'] as string) ?? '';
        item.type = (obj['type'] as number) ?? 1;
        item.title = (obj['title'] as string) ?? '';
        item.description = (obj['description'] as string) ?? '';
        const imgObj: Object = obj['images'];
        item.images = (imgObj !== null && imgObj !== undefined) ? (imgObj as string) : '[]';
        item.locationDesc = (obj['locationDesc'] as string) ?? '';
        item.category = (obj['category'] as string) ?? '';
        const phObj: Object = obj['contactPhone'];
        item.contactPhone = (phObj !== null && phObj !== undefined) ? (phObj as string) : '';
        item.status = (obj['status'] as number) ?? 1;
        item.createTime = (obj['createTime'] as string) ?? '';
        list.push(item);
      }
      this.items = list;
    }
    this.isLoading = false;
  }

  private async markAsDone(item: LostFoundItem): Promise<void> {
    AlertDialog.show({
      title: '确认操作',
      message: '确定将"' + item.title + '"标记为已找到/已归还吗？此操作将删除该记录。',
      primaryButton: { value: '取消', action: () => {} },
      confirm: {
        value: '标记完成',
        fontColor: Theme.success,
        action: async () => {
          const result = await ApiService.deleteLostFound(item.id);
          if (result.code === 200) {
            promptAction.showToast({ message: '已标记为已找到' });
            const newArr: LostFoundItem[] = [];
            for (let i = 0; i < this.items.length; i++) {
              if (this.items[i].id !== item.id) {
                newArr.push(this.items[i]);
              }
            }
            this.items = newArr;
          } else {
            AlertDialog.show({
              message: result.msg || '操作失败',
              confirm: { value: '好的', action: () => {} }
            });
          }
        }
      }
    });
  }

  private async deleteItem(item: LostFoundItem): Promise<void> {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除"' + item.title + '"吗？此操作不可恢复。',
      primaryButton: { value: '取消', action: () => {} },
      confirm: {
        value: '删除',
        fontColor: Theme.danger,
        action: async () => {
          const result = await ApiService.deleteLostFound(item.id);
          if (result.code === 200) {
            promptAction.showToast({ message: '已删除' });
            const newArr: LostFoundItem[] = [];
            for (let i = 0; i < this.items.length; i++) {
              if (this.items[i].id !== item.id) {
                newArr.push(this.items[i]);
              }
            }
            this.items = newArr;
          } else {
            AlertDialog.show({
              message: result.msg || '删除失败',
              confirm: { value: '好的', action: () => {} }
            });
          }
        }
      }
    });
  }

  private goToDetail(item: LostFoundItem): void {
    router.pushUrl({
      url: 'pages/LostFoundDetailPage',
      params: { 'id': item.id.toString() } as Record<string, string>
    });
  }

  private goToPublish(): void {
    router.pushUrl({ url: 'pages/LostFoundPublishPage' });
  }

  build() {
    Column() {
      NavHeader({ title: '我的失物招领' }) {
        Text('发布').fontSize(14).fontColor(Theme.secondary).onClick(() => { this.goToPublish() })
      }

      if (!this.isLoggedIn) {
        Column() {
          Text('🔒').fontSize(48)
          Text('请先登录')
            .fontSize(16).fontColor(Theme.textSecondary).margin({ top: 12 })
          Button('去登录')
            .type(ButtonType.Capsule).backgroundColor(Theme.secondary).fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        Column() {
          LoadingProgress().color(Theme.secondary).width(36).height(36)
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0) {
        Column() {
          Column() {
            Text('📋').fontSize(56)
            Text('还没有发布过失物招领')
              .fontSize(15).fontColor(Theme.textSecondary).margin({ top: 8 })
            Text('点击右上角发布信息')
              .fontSize(13).fontColor(Theme.textTertiary).margin({ top: 4 })
            Button('去发布')
              .type(ButtonType.Capsule).backgroundColor(Theme.secondary).fontColor('#FFFFFF')
              .margin({ top: 20 })
              .onClick(() => { this.goToPublish() })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 60 })
        }
        .width('100%').layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            ForEach(this.items, (item: LostFoundItem) => {
              MyLFItemCard({
                itemData: item,
                onTapCallback: () => this.goToDetail(item),
                onMarkDone: (i: LostFoundItem) => this.markAsDone(i),
                onDelete: (i: LostFoundItem) => this.deleteItem(i)
              })
            }, (item: LostFoundItem) => item.id.toString())
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 0, bottom: 20 })
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }
}
