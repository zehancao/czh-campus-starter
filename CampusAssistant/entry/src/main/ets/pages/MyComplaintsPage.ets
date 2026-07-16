import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { ApiService } from '../service/ApiService'
import { AppStore } from '../service/AppStore'

const STATUS: string[] = ['待处理', '已处理']

interface CItem {
  id: number
  cId: number
  cName: string
  dId: number
  dName: string
  why: string
  stat: number
  when: string
}

@Component
struct CreditCard {
  private score: number = 100

  build() {
    Row() {
      Column() {
        Text('信用分').fontSize(13).fontColor('#FFFFFF').opacity(0.85)
        Text(this.score.toString()).fontSize(36).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        Text(this.score >= 85 ? '可发布商品' : '信用分不足').fontSize(12).fontColor('#FFFFFF').opacity(0.9).margin({ top: 2 })
      }.alignItems(HorizontalAlign.Center).layoutWeight(1)
      Divider().vertical(true).height(50).color('#FFFFFF').opacity(0.25)
      Column() {
        Text('信用等级').fontSize(13).fontColor('#FFFFFF').opacity(0.85)
        Text(this.getLevel()).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      }.alignItems(HorizontalAlign.Center).layoutWeight(1)
    }.width('100%').height(110)
    .backgroundColor(this.score >= 90 ? '#10B981' : this.score >= 80 ? '#F59E0B' : '#EF4444')
    .borderRadius(16)
  }
  getLevel(): string { return this.score >= 90 ? '优秀' : this.score >= 80 ? '良好' : this.score >= 70 ? '一般' : '较差' }
}

@Component
struct CCard {
  private isMy: boolean = false
  private who: string = ''
  private why: string = ''
  private stat: number = 0
  private when: string = ''

  build() {
    Column() {
      Row() {
        Text(this.isMy ? '⚖️' : '👤').fontSize(22).width(40).height(40).textAlign(TextAlign.Center)
          .backgroundColor(this.isMy ? '#FFF3ED' : '#FEF2F2').borderRadius(20)
        Column() {
          Row() {
            Text(this.who).fontSize(15).fontWeight(FontWeight.Medium)
            Blank()
            Text(STATUS[Math.max(0, Math.min(this.stat, 1))]).fontSize(11)
              .fontColor(this.stat === 0 ? '#F59E0B' : '#10B981')
              .backgroundColor(this.stat === 0 ? '#FEF3C7' : '#ECFDF5')
              .borderRadius(4).padding({ left: 7, right: 7, top: 2, bottom: 2 })
          }.width('100%')
          Text(this.isMy ? '被投诉人' : '投诉人').fontSize(11).fontColor('#9CA3AF').margin({ top: 2 })
        }.layoutWeight(1).margin({ left: 10 })
      }.width('100%')
      Divider().height(1).color('#F3F4F6').margin({ top: 10, bottom: 10 })
      Text(this.why).fontSize(13).fontColor('#374151').width('100%').maxLines(5).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row() { Blank(); Text(this.fmt(this.when)).fontSize(11).fontColor('#9CA3AF') }.width('100%').margin({ top: 6 })
    }.width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(12).margin({ bottom: 10 })
  }
  fmt(s: string): string {
    if (!s) return ''; const t = s.replace('T', ' '); return t.length > 16 ? t.substring(0, 16) : t
  }
}

@CustomDialog
struct ComplaintDlg {
  private controller: CustomDialogController
  private dName: string = ''
  private onSubmit?: (reason: string) => void

  @State private reason: string = ''

  build() {
    Column() {
      Text('投诉举报')
        .fontSize(18).fontWeight(FontWeight.Bold)
        .margin({ top: 16 })

      if (this.dName.length > 0) {
        Text('被投诉用户：' + this.dName)
          .fontSize(14).fontColor('#6B7280')
          .margin({ top: 8 })
      }

      TextArea({
        placeholder: '请详细描述投诉原因…',
        text: this.reason
      })
        .width('100%').height(120)
        .fontSize(14).backgroundColor('#F9FAFB')
        .borderRadius(8).padding(12)
        .margin({ top: 12 })
        .onChange((val: string) => { this.reason = val })

      Row() {
        Button('取消')
          .type(ButtonType.Capsule)
          .fontColor('#6B7280').backgroundColor('#F3F4F6')
          .layoutWeight(1).margin({ right: 8 })
          .onClick(() => { this.controller.close() })

        Button('提交投诉')
          .type(ButtonType.Capsule)
          .backgroundColor(this.reason.trim().length >= 2 ? '#EF4444' : '#D1D5DB')
          .fontColor('#FFFFFF')
          .layoutWeight(1).margin({ left: 8 })
          .enabled(this.reason.trim().length >= 2)
          .onClick(() => {
            if (this.onSubmit !== undefined) {
              this.onSubmit(this.reason.trim())
            }
            this.controller.close()
          })
      }.width('100%').margin({ top: 16, bottom: 16 })
    }.width('100%').padding({ left: 20, right: 20 }).backgroundColor('#FFFFFF').borderRadius(16)
  }
}

@Entry
@Component
struct MyComplaintsPage {
  @State score: number = 100
  @State myItems: CItem[] = []
  @State agItems: CItem[] = []
  @State loading: boolean = true

  private dId: number = 0
  private dName: string = ''
  private pId: number = 0

  aboutToAppear(): void {
    try {
      const p = router.getParams() as Record<string, Object>
      if (p) {
        this.dId = p['defendantId'] !== undefined ? Number(p['defendantId']) : 0
        this.dName = (p['defendantName'] as string) ?? ''
        this.pId = p['productId'] !== undefined ? Number(p['productId']) : 0
      }
    } catch (e) {}
    if (!AppStore.getInstance().isLoggedIn) { this.loading = false; return }
    this.loadAll()
  }

  async loadAll(): Promise<void> {
    this.loading = true
    const sr = await ApiService.getCreditScore()
    if (sr.code === 200 && sr.data) {
      const d = sr.data as Record<string, Object>
      this.score = (d['creditScore'] as number) ?? 100
    }
    const me = AppStore.getInstance().userInfo.id
    const lr = await ApiService.getMyComplaints()
    const a: CItem[] = []; const b: CItem[] = []
    if (lr.code === 200 && lr.data) {
      for (const o of lr.data as Object[]) {
        const obj = o as Record<string, Object>
        const c: CItem = {
          id: (obj['id'] as number) ?? 0,
          cId: (obj['complainantId'] as number) ?? 0,
          cName: (obj['complainantName'] as string) ?? '',
          dId: (obj['defendantId'] as number) ?? 0,
          dName: (obj['defendantName'] as string) ?? '',
          why: (obj['reason'] as string) ?? '',
          stat: (obj['status'] as number) ?? 0,
          when: (obj['createTime'] as string) ?? ''
        }
        if (c.cId === me) a.push(c)
        if (c.dId === me) b.push(c)
      }
    }
    this.myItems = a; this.agItems = b; this.loading = false
    if (this.dId > 0) setTimeout(() => this.showDlg(), 150)
  }

  private dlgController: CustomDialogController | null = null

  showDlg(): void {
    if (AppStore.getInstance().userInfo.id === this.dId) {
      AlertDialog.show({ message: '不能投诉自己', confirm: { value: '好的', action: () => {} } })
      return
    }
    this.dlgController = new CustomDialogController({
      builder: ComplaintDlg({
        dName: this.dName,
        onSubmit: (reason: string) => this.doSubmit(reason)
      }),
      autoCancel: true,
      cancel: () => { this.dId = 0; this.dName = ''; this.pId = 0 },
      alignment: DialogAlignment.Bottom,
      customStyle: true
    })
    this.dlgController.open()
  }

  async doSubmit(r: string): Promise<void> {
    const p: Record<string, Object> = { 'defendantId': this.dId, 'reason': r }
    if (this.pId > 0) p['productId'] = this.pId
    const res = await ApiService.submitComplaint(p)
    if (res.code === 200) {
      promptAction.showToast({ message: '投诉已提交，对方信用分 -5', duration: 2000 })
      this.dId = 0; this.dName = ''; this.pId = 0
      this.loadAll()
    } else {
      AlertDialog.show({ message: res.msg || '提交失败', confirm: { value: '好的', action: () => {} } })
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('‹ 返回')
          .fontSize(16)
          .fontColor('#6B7280')
          .onClick(() => {
            router.back()
          })
        Blank()
        Text('投诉与信用')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        if (this.myItems.length + this.agItems.length > 0) {
          Text('共' + (this.myItems.length + this.agItems.length) + '条')
            .fontSize(13)
            .fontColor('#9CA3AF')
        } else {
          Blank().width(48)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (!AppStore.getInstance().isLoggedIn) {
        Column() {
          Text('🔒')
            .fontSize(56)
          Text('请先登录')
            .fontSize(16)
            .fontColor('#6B7280')
            .margin({ top: 12 })
          Button('去登录')
            .type(ButtonType.Capsule)
            .backgroundColor('#FF6B35')
            .fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' })
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.loading) {
        Column() {
          LoadingProgress()
            .color('#FF6B35')
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 绿色信用卡片
            CreditCard({ score: this.score })
              .margin({ bottom: 0 })

            // 提示条，紧贴绿卡
            Row() {
              Text('⚠️')
                .fontSize(14)
              Text('每次有效投诉，被投诉人信用分 -5')
                .fontSize(12)
                .fontColor('#9CA3AF')
                .margin({ left: 4 })
            }
            .width('100%')
            .margin({ top: 0, bottom: 12 })

            // 投诉内容卡片组
            Column() {
              Row() {
                Text('📝 投诉内容')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                Blank()
                Text(this.myItems.length + '条')
                  .fontSize(12)
                  .fontColor('#9CA3AF')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 8 })

              if (this.myItems.length === 0) {
                Column() {
                  Text('暂无投诉记录')
                    .fontSize(14)
                    .fontColor('#9CA3AF')
                }
                .width('100%')
                .padding({ top: 18, bottom: 18 })
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              } else {
                ForEach(this.myItems, (item: CItem) => {
                  CCard({
                    isMy: true,
                    who: item.dName,
                    why: item.why,
                    stat: item.stat,
                    when: item.when
                  })
                }, (item: CItem) => 'm' + item.id)
              }
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })

            // 自己的被投诉记录卡片组
            Column() {
              Row() {
                Text('📋 自己的被投诉记录')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                Blank()
                Text(this.agItems.length + '条')
                  .fontSize(12)
                  .fontColor('#9CA3AF')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 8 })

              if (this.agItems.length === 0) {
                Column() {
                  Text('没有被投诉记录')
                    .fontSize(14)
                    .fontColor('#9CA3AF')
                }
                .width('100%')
                .padding({ top: 18, bottom: 18 })
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              } else {
                ForEach(this.agItems, (item: CItem) => {
                  CCard({
                    isMy: false,
                    who: item.cName,
                    why: item.why,
                    stat: item.stat,
                    when: item.when
                  })
                }, (item: CItem) => 'a' + item.id)
              }
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 2 })
            .margin({ top: 12 })

            Blank().height(24)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 0 })
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
  }
}
