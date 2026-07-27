import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { SafetyReport } from '../model/Models';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';
import { AppStore } from '../service/AppStore';

const STATUS_LABELS: Record<string, string> = {
  '0': '待处理',
  '1': '处理中',
  '2': '已解决',
  '3': '误报'
};
const STATUS_COLORS: Record<string, string> = {
  '0': Theme.danger,
  '1': Theme.warning,
  '2': Theme.success,
  '3': Theme.textDisabled
};
const TYPE_ICONS: Record<string, string> = {
  '人身安全': '🚨',
  '财物丢失': '💰',
  '火情': '🔥',
  '医疗': '🏥',
  '其他': '⚠️'
};

@Entry
@Component
struct SafetyReportDetailPage {
  @State private report: SafetyReport = new SafetyReport();
  @State private isLoading: boolean = true;
  @State private handleRemark: string = '';
  @State private selectedStatus: number = 1;
  private reportId: number = 0;

  aboutToAppear(): void {
    const params: Record<string, string> = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined && params['id'] !== undefined) {
      this.reportId = parseInt(params['id'], 10);
    }
    this.loadDetail();
  }

  private async loadDetail(): Promise<void> {
    this.isLoading = true;
    const result = await ApiService.getSafetyDetail(this.reportId);
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      this.report = new SafetyReport();
      this.report.id = (obj['id'] as number) ?? 0;
      this.report.userId = (obj['userId'] as number) ?? 0;
      this.report.reporterName = (obj['reporterName'] as string) ?? '';
      this.report.reporterPhone = (obj['reporterPhone'] as string) ?? '';
      this.report.type = (obj['type'] as string) ?? '';
      this.report.location = (obj['location'] as string) ?? '';
      this.report.description = (obj['description'] as string) ?? '';
      const imgObj: Object = obj['images'];
      if (imgObj !== null && imgObj !== undefined) {
        const imgArr: Object[] = imgObj as Object[];
        this.report.images = [];
        for (let j = 0; j < imgArr.length; j++) {
          this.report.images.push(imgArr[j] as string);
        }
      }
      this.report.status = (obj['status'] as number) ?? 0;
      this.report.handlerId = (obj['handlerId'] as number) ?? 0;
      this.report.handlerName = (obj['handlerName'] as string) ?? '';
      this.report.handleRemark = (obj['handleRemark'] as string) ?? '';
      this.report.createTime = (obj['createTime'] as string) ?? '';
      this.report.handleTime = (obj['handleTime'] as string) ?? '';
    }
    this.isLoading = false;
  }

  private async doHandle(): Promise<void> {
    const result = await ApiService.handleSafetyReport(this.reportId, this.selectedStatus, this.handleRemark);
    if (result.code === 200) {
      this.loadDetail();
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
      NavHeader({ title: '求助详情' })

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
                Text(TYPE_ICONS[this.report.type] ?? '⚠️').fontSize(24)
                Text(this.report.type)
                  .fontSize(16).fontColor(Theme.textPrimary).fontWeight(FontWeight.Bold)
                  .margin({ left: 8 })
                Blank()
                Text(STATUS_LABELS[`${this.report.status}`] ?? '未知')
                  .fontSize(12).fontWeight(FontWeight.Medium)
                  .fontColor(STATUS_COLORS[`${this.report.status}`] ?? Theme.textTertiary)
                  .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                  .borderRadius(10)
                  .backgroundColor('#F3F4F6')
              }
              .width('100%')

              if (this.report.location.length > 0) {
                Row() {
                  Text('📍').fontSize(14)
                  Text(this.report.location)
                    .fontSize(14).fontColor(Theme.textSecondary).margin({ left: 4 })
                }
                .width('100%').margin({ top: 12 })
              }

              if (this.report.description.length > 0) {
                Column() {
                  Text('情况描述')
                    .fontSize(12).fontColor(Theme.textTertiary).width('100%')
                  Text(this.report.description)
                    .fontSize(14).fontColor(Theme.textPrimary).margin({ top: 4 }).width('100%')
                    .lineHeight(22)
                }
                .width('100%').margin({ top: 12 })
              }

              if (this.report.images.length > 0) {
                Row() {
                  ForEach(this.report.images, (img: string, index: number) => {
                    Image(`${ApiService.baseUrl}${img}`)
                      .width(80).height(80).borderRadius(8)
                      .objectFit(ImageFit.Cover).margin({ right: 6 })
                  }, (img: string, index: number) => `${index}`)
                }
                .width('100%').margin({ top: 12 })
              }

              Divider().margin({ top: 12, bottom: 12 }).color(Theme.border)

              Row() {
                Text('报告人：')
                  .fontSize(12).fontColor(Theme.textTertiary)
                Text(this.report.reporterName)
                  .fontSize(12).fontColor(Theme.textPrimary)
                if (this.report.reporterPhone.length > 0) {
                  Text(this.report.reporterPhone)
                    .fontSize(12).fontColor(Theme.primary).margin({ left: 8 })
                }
              }
              .width('100%')

              Row() {
                Text('报告时间：')
                  .fontSize(12).fontColor(Theme.textTertiary)
                Text(this.formatTime(this.report.createTime))
                  .fontSize(12).fontColor(Theme.textPrimary)
              }
              .width('100%').margin({ top: 6 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(Theme.cardRadius)

            if (this.report.status > 0) {
              Column() {
                Text('处理信息')
                  .fontSize(14).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
                  .width('100%').margin({ bottom: 8 })

                Row() {
                  Text('处理人：')
                    .fontSize(12).fontColor(Theme.textTertiary)
                  Text(this.report.handlerName)
                    .fontSize(12).fontColor(Theme.textPrimary)
                }
                .width('100%')

                Row() {
                  Text('处理时间：')
                    .fontSize(12).fontColor(Theme.textTertiary)
                  Text(this.formatTime(this.report.handleTime))
                    .fontSize(12).fontColor(Theme.textPrimary)
                }
                .width('100%').margin({ top: 6 })

                if (this.report.handleRemark.length > 0) {
                  Column() {
                    Text('处理备注：')
                      .fontSize(12).fontColor(Theme.textTertiary).width('100%')
                    Text(this.report.handleRemark)
                      .fontSize(13).fontColor(Theme.textPrimary).margin({ top: 2 }).width('100%')
                  }
                  .width('100%').margin({ top: 6 })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(Theme.cardRadius)
              .margin({ top: 10 })
            }

            if (this.report.status === 0) {
              Column() {
                Text('处理此求助')
                  .fontSize(14).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
                  .width('100%').margin({ bottom: 8 })

                Row({ space: 8 }) {
                  Button('处理中')
                    .fontSize(12).height(32).type(ButtonType.Normal)
                    .backgroundColor(this.selectedStatus === 1 ? Theme.warning : '#F3F4F6')
                    .fontColor(this.selectedStatus === 1 ? '#FFFFFF' : Theme.textSecondary)
                    .borderRadius(16)
                    .onClick(() => { this.selectedStatus = 1 })

                  Button('已解决')
                    .fontSize(12).height(32).type(ButtonType.Normal)
                    .backgroundColor(this.selectedStatus === 2 ? Theme.success : '#F3F4F6')
                    .fontColor(this.selectedStatus === 2 ? '#FFFFFF' : Theme.textSecondary)
                    .borderRadius(16)
                    .onClick(() => { this.selectedStatus = 2 })

                  Button('误报')
                    .fontSize(12).height(32).type(ButtonType.Normal)
                    .backgroundColor(this.selectedStatus === 3 ? Theme.textDisabled : '#F3F4F6')
                    .fontColor(this.selectedStatus === 3 ? '#FFFFFF' : Theme.textSecondary)
                    .borderRadius(16)
                    .onClick(() => { this.selectedStatus = 3 })
                }
                .width('100%')

                TextInput({ placeholder: '处理备注（可选）', text: this.handleRemark })
                  .fontSize(13).width('100%').height(40).margin({ top: 8 })
                  .backgroundColor('#F3F4F6').borderRadius(8)
                  .onChange((value: string) => { this.handleRemark = value })

                Button('提交处理')
                  .width('100%').height(40).type(ButtonType.Normal)
                  .backgroundColor(Theme.primary).fontColor('#FFFFFF')
                  .borderRadius(Theme.radiusMd).fontSize(14)
                  .margin({ top: 8 })
                  .onClick(() => { this.doHandle() })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(Theme.cardRadius)
              .margin({ top: 10 })
            }
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
