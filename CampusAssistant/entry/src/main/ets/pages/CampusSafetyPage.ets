import { call } from '@kit.TelephonyKit';
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../service/ApiService';
import { SafetyContact } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const HOLD_DURATION: number = 2000;
const TICK_INTERVAL: number = 30;

const CATEGORY_COLORS: Record<string, string> = {
  '安保': '#3B82F6',
  '医疗': '#EF4444',
  '消防': '#F97316',
  '心理': '#10B981',
  '其他': '#6B7280'
};

@Entry
@Component
struct CampusSafetyPage {
  @State private contacts: SafetyContact[] = [];
  @State private showPhones: boolean = false;
  @State private isLoading: boolean = false;
  @State private progressValue: number = 0;
  @State private isHolding: boolean = false;
  @State private isSubmitting: boolean = false;
  @State private locationText: string = '';
  @State private manualLocation: string = '';
  @State private showManualInput: boolean = false;
  private holdTimer: number = -1;
  private tickCount: number = 0;
  private maxTicks: number = Math.floor(HOLD_DURATION / TICK_INTERVAL);

  aboutToDisappear(): void {
    if (this.holdTimer !== -1) {
      clearInterval(this.holdTimer);
    }
  }

  private startHold(): void {
    this.isHolding = true;
    this.progressValue = 0;
    this.tickCount = 0;
    this.holdTimer = setInterval(() => {
      this.tickCount = this.tickCount + 1;
      this.progressValue = this.tickCount / this.maxTicks;
      if (this.tickCount >= this.maxTicks) {
        clearInterval(this.holdTimer);
        this.holdTimer = -1;
        this.isHolding = false;
        this.progressValue = 0;
        this.onHoldComplete();
      }
    }, TICK_INTERVAL);
  }

  private cancelHold(): void {
    if (this.holdTimer !== -1) {
      clearInterval(this.holdTimer);
      this.holdTimer = -1;
    }
    this.isHolding = false;
    this.progressValue = 0;
  }

  private async onHoldComplete(): Promise<void> {
    this.isSubmitting = true;
    this.locationText = '正在获取位置...';

    let locationStr: string = '';
    let locationFailed: boolean = false;
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const atManager = abilityAccessCtrl.createAtManager();
      const grantResult = await atManager.requestPermissionsFromUser(context, ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']);
      let hasLocation: boolean = false;
      for (let i = 0; i < grantResult.authResults.length; i++) {
        if (grantResult.authResults[i] === 0) {
          hasLocation = true;
          break;
        }
      }

      if (hasLocation) {
        const isLocEnabled: boolean = geoLocationManager.isLocationEnabled();
        if (!isLocEnabled) {
          locationFailed = true;
          locationStr = '';
        } else {
          const requestInfo: geoLocationManager.SingleLocationRequest = {
            locatingPriority: geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
            locatingTimeoutMs: 10000
          };
          const loc: geoLocationManager.Location = await geoLocationManager.getCurrentLocation(requestInfo);
          let addressStr: string = `${loc.latitude.toFixed(4)},${loc.longitude.toFixed(4)}`;
          try {
            if (geoLocationManager.isGeocoderAvailable()) {
              const reverseRequest: geoLocationManager.ReverseGeoCodeRequest = {
                latitude: loc.latitude,
                longitude: loc.longitude,
                maxItems: 1
              };
              const addresses: Array<geoLocationManager.GeoAddress> = await geoLocationManager.getAddressesFromLocation(reverseRequest);
              if (addresses.length > 0) {
                const addr: geoLocationManager.GeoAddress = addresses[0];
                const parts: string[] = [];
                if (addr.administrativeArea !== undefined && addr.administrativeArea.length > 0) {
                  parts.push(addr.administrativeArea);
                }
                if (addr.locality !== undefined && addr.locality.length > 0) {
                  parts.push(addr.locality);
                }
                if (addr.subLocality !== undefined && addr.subLocality.length > 0) {
                  parts.push(addr.subLocality);
                }
                if (addr.roadName !== undefined && addr.roadName.length > 0) {
                  parts.push(addr.roadName);
                }
                if (addr.placeName !== undefined && addr.placeName.length > 0 && parts.indexOf(addr.placeName) === -1) {
                  parts.push(addr.placeName);
                }
                if (parts.length > 0) {
                  addressStr = parts.join('');
                }
              }
            }
          } catch (geoErr) {
            addressStr = `${loc.latitude.toFixed(4)},${loc.longitude.toFixed(4)}`;
          }
          locationStr = addressStr;
        }
      } else {
        locationFailed = true;
        locationStr = '';
      }
    } catch (e) {
      locationFailed = true;
      locationStr = '';
    }
    this.locationText = locationStr;
    this.isSubmitting = false;

    if (locationFailed) {
      this.showManualInput = true;
      return;
    }

    this.doSubmit(locationStr);
  }

  private async doSubmit(locationStr: string): Promise<void> {
    this.isSubmitting = true;
    const params: Record<string, Object> = {
      'type': 'emergency',
      'location': locationStr,
      'description': '长按紧急求助按钮触发',
      'images': '[]',
    };
    const submitResult = await ApiService.submitSafetyReport(params);
    this.isSubmitting = false;
    if (submitResult.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '求助已提交', duration: 2000 });
    } else {
      this.getUIContext().getPromptAction().showToast({ message: `提交失败: ${submitResult.msg}`, duration: 3000 });
    }

    if (this.contacts.length === 0) {
      this.isLoading = true;
      const result = await ApiService.getSafetyContacts();
      if (result.code === 200 && result.data !== undefined) {
        this.contacts = ApiService.parseSafetyContacts(result.data);
      }
      this.isLoading = false;
    }
    this.showPhones = true;
  }

  private makeCall(phone: string): void {
    call.makeCall(phone, (err: BusinessError) => {
      if (err) {
        this.getUIContext().getPromptAction().showToast({ message: '拨号失败', duration: 2000 });
      }
    });
  }

  private getFiltered(category: string): SafetyContact[] {
    const result: SafetyContact[] = [];
    for (let i = 0; i < this.contacts.length; i++) {
      if (this.contacts[i].category === category) {
        result.push(this.contacts[i]);
      }
    }
    return result;
  }

  build() {
    Column() {
      NavHeader({ title: '校园安全' })

      Scroll() {
        Column() {
          Stack() {
            Progress({ value: this.progressValue, total: 1, type: ProgressType.Ring })
              .width(220).height(220)
              .color(Theme.danger)
              .style({ strokeWidth: 6 })
              .visibility(this.isHolding ? Visibility.Visible : Visibility.Hidden)

            Column() {
              Text('🆘').fontSize(56)
              Text('紧急求助')
                .fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold).margin({ top: 4 })
              Text(this.isHolding ? '请持续按住...' : '长按2秒')
                .fontSize(13).fontColor('rgba(255,255,255,0.7)').margin({ top: 4 })
            }
            .width(180).height(180)
            .borderRadius(90)
            .backgroundColor(this.isHolding ? '#DC2626' : Theme.danger)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .shadow({ radius: this.isHolding ? 32 : 24, color: '#EF444480', offsetY: 8 })
          }
          .width(220).height(220)
          .margin({ top: 36 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.startHold();
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.cancelHold();
            }
          })

          if (this.isSubmitting) {
            Column() {
              LoadingProgress().color(Theme.primary).width(28).height(28)
              Text(this.locationText)
                .fontSize(13).fontColor(Theme.textSecondary).margin({ top: 8 })
            }
            .margin({ top: 20 })
          }

          if (this.showManualInput) {
            Column() {
              Text('⚠️ 定位服务未开启，请输入当前位置')
                .fontSize(14).fontColor(Theme.danger).fontWeight(FontWeight.Medium)
                .width('100%').textAlign(TextAlign.Center)
                .margin({ bottom: 12 })
              TextInput({ placeholder: '例如：3号教学楼2层', text: $$this.manualLocation })
                .width('100%')
                .height(44)
                .borderRadius(Theme.radiusMd)
                .backgroundColor('#FFFFFF')
                .padding({ left: 16, right: 16 })
              Button('提交求助')
                .width('100%')
                .height(44)
                .backgroundColor(Theme.danger)
                .fontColor('#FFFFFF')
                .borderRadius(Theme.radiusMd)
                .margin({ top: 12 })
                .onClick(() => {
                  if (this.manualLocation.length === 0) {
                    this.getUIContext().getPromptAction().showToast({ message: '请输入当前位置', duration: 2000 });
                    return;
                  }
                  this.showManualInput = false;
                  this.doSubmit(this.manualLocation);
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .margin({ top: 20 })
          }

          if (this.showPhones && this.contacts.length > 0) {
            Column() {
              Text('求助已发送！请立即拨打以下电话')
                .fontSize(14).fontColor(Theme.danger).fontWeight(FontWeight.Medium)
                .width('100%').textAlign(TextAlign.Center)
                .margin({ top: 20, bottom: 16 })

              this.ContactSection('🏥 医疗急救', '医疗')
              this.ContactSection('🛡️ 校内救援', '安保')
              this.ContactSection('🚒 消防报警', '消防')
              this.ContactSection('💚 心理援助', '心理')
              this.ContactSection('📞 其他服务', '其他')
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }
        }
        .width('100%')
        .padding({ bottom: 24 })
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%').backgroundColor(Theme.bgPage)
  }

  @Builder
  ContactSection(title: string, category: string) {
    if (category === '安保' || category === '医疗' || category === '消防' || category === '心理' || category === '其他') {
      Column() {
        Text(title)
          .fontSize(15).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
          .width('100%').margin({ bottom: 8 })

        ForEach(this.getFiltered(category), (c: SafetyContact) => {
          Row() {
            Text(c.name)
              .fontSize(16).fontColor(Theme.textPrimary).fontWeight(FontWeight.Medium)
              .layoutWeight(1)

            Row() {
              Text(c.phone)
                .fontSize(20).fontColor(Theme.primary).fontWeight(FontWeight.Bold)
              Text(' 📞')
                .fontSize(22)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor('#FFFFFF')
          .borderRadius(Theme.radiusMd)
          .margin({ bottom: 6 })
          .shadow(ShadowStyle.sm)
          .onClick(() => { this.makeCall(c.phone) })
        }, (c: SafetyContact) => `${c.id}`)
      }
      .width('100%')
      .margin({ bottom: 16 })
    }
  }
}
