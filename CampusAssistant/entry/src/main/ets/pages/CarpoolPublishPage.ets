import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { Theme } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

@Entry
@Component
struct CarpoolPublishPage {
  @State private departure: string = '';
  @State private destination: string = '';
  @State private departureDate: string = '';
  @State private departureHour: string = '08';
  @State private departureMinute: string = '00';
  @State private maxPassengers: string = '4';
  @State private contactPhone: string = '';
  @State private remark: string = '';
  @State private isSubmitting: boolean = false;

  private hours: string[] = [];
  private minutes: string[] = [];

  aboutToAppear(): void {
    for (let i = 0; i < 24; i++) {
      this.hours.push(i < 10 ? `0${i}` : `${i}`);
    }
    for (let i = 0; i < 60; i += 5) {
      this.minutes.push(i < 10 ? `0${i}` : `${i}`);
    }
  }

  private async doPublish(): Promise<void> {
    if (this.departure.length === 0) {
      this.showToast('请填写出发地');
      return;
    }
    if (this.destination.length === 0) {
      this.showToast('请填写目的地');
      return;
    }
    if (this.departureDate.length === 0) {
      this.showToast('请选择出发日期');
      return;
    }

    if (this.contactPhone.length === 0) {
      this.showToast('请填写联系电话');
      return;
    }
    if (this.contactPhone.length !== 11) {
      this.showToast('联系电话需为11位手机号');
      return;
    }

    this.isSubmitting = true;
    const departureTime: string = `${this.departureDate} ${this.departureHour}:${this.departureMinute}`;
    const maxP: number = parseInt(this.maxPassengers, 10);
    const params: Record<string, Object> = {
      'departure': this.departure,
      'destination': this.destination,
      'departureTime': departureTime,
      'maxPassengers': isNaN(maxP) ? 4 : maxP,
      'contactPhone': this.contactPhone,
      'remark': this.remark,
    };
    const result = await ApiService.publishCarpool(params);
    this.isSubmitting = false;
    if (result.code === 200) {
      this.showToast('发布成功');
      router.back();
    } else {
      this.showToast(`发布失败: ${result.msg}`);
    }
  }

  private showToast(msg: string): void {
    const ctx = this.getUIContext();
    ctx.getPromptAction().showToast({ message: msg, duration: 2000 });
  }

  build() {
    Column() {
      NavHeader({ title: '发布拼车' })

      Scroll() {
        Column() {
          Column() {
            Text('出发地 *')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            TextInput({ placeholder: '如：北门', text: this.departure })
              .fontSize(14).width('100%').margin({ top: 4 })
              .onChange((value: string) => { this.departure = value })
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('目的地 *')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            TextInput({ placeholder: '如：火车站', text: this.destination })
              .fontSize(14).width('100%').margin({ top: 4 })
              .onChange((value: string) => { this.destination = value })
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('出发日期 *')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            DatePicker()
              .onChange((value: DatePickerResult) => {
                const y: number = value.year ?? 2026;
                const m: number = (value.month ?? 0) + 1;
                const d: number = value.day ?? 1;
                this.departureDate = `${y}-${m < 10 ? '0' + m : m}-${d < 10 ? '0' + d : d}`;
              })
              .margin({ top: 4 })
          }
          .width('100%').margin({ bottom: 12 })

          Row() {
            Column() {
              Text('时')
                .fontSize(12).fontColor(Theme.textTertiary).width('100%')
              TextPicker({ range: this.hours, selected: 8 })
                .onChange((value: string | string[], index: number | number[]) => {
                  if (typeof value === 'string') {
                    this.departureHour = value;
                  }
                })
                .height(120)
            }
            .layoutWeight(1)

            Column() {
              Text('分')
                .fontSize(12).fontColor(Theme.textTertiary).width('100%')
              TextPicker({ range: this.minutes, selected: 0 })
                .onChange((value: string | string[], index: number | number[]) => {
                  if (typeof value === 'string') {
                    this.departureMinute = value;
                  }
                })
                .height(120)
            }
            .layoutWeight(1)
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('最大乘客数（不含司机）')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            TextInput({ placeholder: '4', text: this.maxPassengers })
              .fontSize(14).type(InputType.Number).width('100%').margin({ top: 4 })
              .onChange((value: string) => { this.maxPassengers = value })
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('联系电话')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            TextInput({ placeholder: '请输入11位手机号', text: this.contactPhone })
              .fontSize(14).type(InputType.PhoneNumber).maxLength(11).width('100%').margin({ top: 4 })
              .onChange((value: string) => { this.contactPhone = value })
          }
          .width('100%').margin({ bottom: 12 })

          Column() {
            Text('备注')
              .fontSize(12).fontColor(Theme.textTertiary).width('100%')
            TextInput({ placeholder: '如：AA、走高速、可放行李等', text: this.remark })
              .fontSize(14).width('100%').margin({ top: 4 })
              .onChange((value: string) => { this.remark = value })
          }
          .width('100%').margin({ bottom: 20 })

          Button('发布拼车')
            .width('100%').height(48).type(ButtonType.Normal)
            .backgroundColor(Theme.primary).fontColor('#FFFFFF')
            .borderRadius(Theme.radiusMd).fontSize(16)
            .enabled(!this.isSubmitting)
            .onClick(() => { this.doPublish() })
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
