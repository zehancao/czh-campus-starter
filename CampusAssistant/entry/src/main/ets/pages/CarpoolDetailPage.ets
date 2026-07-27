import { router } from '@kit.ArkUI';
import { ApiService, ApiResult } from '../service/ApiService';
import { CarpoolOrder, PassengerItem } from '../model/Models';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';
import { AppStore } from '../service/AppStore';

const STATUS_LABELS: Record<string, string> = {
  '0': '招募中',
  '1': '已满',
  '2': '已出发',
  '3': '已取消'
};
const STATUS_COLORS: Record<string, string> = {
  '0': Theme.success,
  '1': Theme.warning,
  '2': Theme.primary,
  '3': Theme.textDisabled
};

@Entry
@Component
struct CarpoolDetailPage {
  @State private order: CarpoolOrder = new CarpoolOrder();
  @State private passengers: PassengerItem[] = [];
  @State private isLoading: boolean = true;
  @State private isOwner: boolean = false;
  private orderId: number = 0;

  aboutToAppear(): void {
    const params: Record<string, string> = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined && params['id'] !== undefined) {
      this.orderId = parseInt(params['id'], 10);
    }
    this.loadDetail();
  }

  private async loadDetail(): Promise<void> {
    this.isLoading = true;
    const result = await ApiService.getCarpoolDetail(this.orderId);
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      this.order = new CarpoolOrder();
      this.order.id = (obj['id'] as number) ?? 0;
      this.order.userId = (obj['userId'] as number) ?? 0;
      this.order.publisherName = (obj['publisherName'] as string) ?? '';
      this.order.publisherAvatar = (obj['publisherAvatar'] as string) ?? '';
      this.order.departure = (obj['departure'] as string) ?? '';
      this.order.destination = (obj['destination'] as string) ?? '';
      this.order.departureTime = (obj['departureTime'] as string) ?? '';
      this.order.maxPassengers = (obj['maxPassengers'] as number) ?? 4;
      this.order.currentPassengers = (obj['currentPassengers'] as number) ?? 0;
      this.order.contactPhone = (obj['contactPhone'] as string) ?? '';
      this.order.remark = (obj['remark'] as string) ?? '';
      this.order.status = (obj['status'] as number) ?? 0;
      this.order.joined = (obj['joined'] as boolean) ?? false;
      this.order.createTime = (obj['createTime'] as string) ?? '';

      const psgObj: Object = obj['passengers'];
      if (psgObj !== null && psgObj !== undefined) {
        this.passengers = ApiService.parsePassengers(psgObj);
      }

      const store: AppStore = AppStore.getInstance();
      this.isOwner = this.order.userId === store.userInfo.id;
    }
    this.isLoading = false;
  }

  private async joinOrder(): Promise<void> {
    const result = await ApiService.joinCarpool(this.orderId);
    if (result.code === 200) {
      this.loadDetail();
    }
  }

  private async cancelJoin(): Promise<void> {
    const result = await ApiService.cancelJoinCarpool(this.orderId);
    if (result.code === 200) {
      this.loadDetail();
    }
  }

  private async cancelOrder(): Promise<void> {
    const result = await ApiService.cancelCarpool(this.orderId);
    if (result.code === 200) {
      this.loadDetail();
    }
  }

  private confirmDeleteCarpool(): void {
    AlertDialog.show({
      message: '确定删除这条拼车信息吗？删除后不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: () => { this.doDeleteCarpool() }
      }
    });
  }

  private async doDeleteCarpool(): Promise<void> {
    const result: ApiResult = await ApiService.deleteCarpool(this.orderId);
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '删除成功', duration: 1500 });
      this.getUIContext().getRouter().back();
    } else {
      const msg: string = result.msg ?? '删除失败';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
    }
  }

  private formatTime(timeStr: string): string {
    if (timeStr.length === 0) return '';
    const t: string = timeStr.replace('T', ' ');
    if (t.length > 16) return t.substring(0, 16);
    return t;
  }

  build() {
    Column() {
      NavHeader({ title: '拼车详情' })

      if (this.isLoading) {
        Column() {
          LoadingProgress().color(Theme.primary).width(36).height(36)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Text(this.order.publisherName)
                  .fontSize(14).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
                Text(this.formatTime(this.order.createTime))
                  .fontSize(11).fontColor(Theme.textTertiary).margin({ left: 8 })
                Blank()
                Text(STATUS_LABELS[`${this.order.status}`] ?? '未知')
                  .fontSize(11).fontWeight(FontWeight.Medium)
                  .fontColor(STATUS_COLORS[`${this.order.status}`] ?? Theme.textTertiary)
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(10)
              }
              .width('100%')

              Row() {
                Column() {
                  Text(this.order.departure)
                    .fontSize(18).fontColor(Theme.textPrimary).fontWeight(FontWeight.Bold)
                  Text('出发地')
                    .fontSize(12).fontColor(Theme.textTertiary).margin({ top: 2 })
                }
                .layoutWeight(1)

                Column() {
                  Text('🚗→').fontSize(24).fontColor(Theme.primary)
                }
                .justifyContent(FlexAlign.Center).width(60)

                Column() {
                  Text(this.order.destination)
                    .fontSize(18).fontColor(Theme.textPrimary).fontWeight(FontWeight.Bold)
                  Text('目的地')
                    .fontSize(12).fontColor(Theme.textTertiary).margin({ top: 2 })
                }
                .layoutWeight(1)
              }
              .width('100%').margin({ top: 16 })

              Divider().margin({ top: 12, bottom: 12 }).color(Theme.border)

              Row() {
                Column() {
                  Text('出发时间')
                    .fontSize(12).fontColor(Theme.textTertiary)
                  Text(this.formatTime(this.order.departureTime))
                    .fontSize(14).fontColor(Theme.textPrimary).margin({ top: 4 })
                }
                .layoutWeight(1)

                Column() {
                  Text('座位情况')
                    .fontSize(12).fontColor(Theme.textTertiary)
                  Text(`${this.order.currentPassengers}/${this.order.maxPassengers}人`)
                    .fontSize(14).fontColor(Theme.primary).margin({ top: 4 })
                }
                .layoutWeight(1)
              }
              .width('100%')

              if (this.order.contactPhone.length > 0) {
                Row() {
                  Text('联系电话')
                    .fontSize(12).fontColor(Theme.textTertiary)
                  Text(this.order.contactPhone)
                    .fontSize(14).fontColor(Theme.primary).margin({ left: 8 })
                }
                .width('100%').margin({ top: 12 })
              }

              if (this.order.remark.length > 0) {
                Column() {
                  Text('备注')
                    .fontSize(12).fontColor(Theme.textTertiary).width('100%')
                  Text(this.order.remark)
                    .fontSize(14).fontColor(Theme.textPrimary).margin({ top: 4 }).width('100%')
                }
                .width('100%').margin({ top: 12 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(Theme.cardRadius)

            if (this.passengers.length > 0) {
              Column() {
                Text('乘客列表')
                  .fontSize(14).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
                  .width('100%').margin({ bottom: 8 })

                ForEach(this.passengers, (p: PassengerItem) => {
                  Row() {
                    Text('👤').fontSize(18)
                    Text(p.nickname)
                      .fontSize(14).fontColor(Theme.textPrimary).margin({ left: 8 })
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                }, (p: PassengerItem) => `${p.userId}`)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(Theme.cardRadius)
              .margin({ top: 10 })
            }

            Column() {
              if (this.isOwner) {
                Button('删除拼车')
                  .width('100%').height(44).type(ButtonType.Normal)
                  .backgroundColor('#FEE2E2').fontColor(Theme.danger)
                  .borderRadius(Theme.radiusMd)
                  .margin({ bottom: 10 })
                  .onClick(() => { this.confirmDeleteCarpool() })
                if (this.order.status === 0) {
                  Button('取消拼车')
                    .width('100%').height(44).type(ButtonType.Normal)
                    .backgroundColor('#FEF3C7').fontColor(Theme.warning)
                    .borderRadius(Theme.radiusMd)
                    .onClick(() => { this.cancelOrder() })
                }
              } else if (this.order.status === 0 || this.order.status === 1) {
                if (this.order.joined) {
                  Button('退出拼车')
                    .width('100%').height(44).type(ButtonType.Normal)
                    .backgroundColor('#FEF3C7').fontColor(Theme.warning)
                    .borderRadius(Theme.radiusMd)
                    .onClick(() => { this.cancelJoin() })
                } else if (this.order.currentPassengers < this.order.maxPassengers) {
                  Button('加入拼车')
                    .width('100%').height(44).type(ButtonType.Normal)
                    .backgroundColor(Theme.primary).fontColor('#FFFFFF')
                    .borderRadius(Theme.radiusMd)
                    .onClick(() => { this.joinOrder() })
                } else {
                  Text('已满员，无法加入')
                    .fontSize(14).fontColor(Theme.textDisabled)
                    .width('100%').textAlign(TextAlign.Center)
                }
              } else if (this.order.status === 3) {
                Text('该拼车已取消')
                  .fontSize(14).fontColor(Theme.textDisabled)
                  .width('100%').textAlign(TextAlign.Center)
              } else if (this.order.status === 2) {
                Text('该拼车已出发')
                  .fontSize(14).fontColor(Theme.textDisabled)
                  .width('100%').textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .margin({ top: 16 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 20 })
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(Theme.bgPage)
  }
}
