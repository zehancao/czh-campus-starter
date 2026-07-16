/**
 * 消息通知列表页
 * 顶部分类 Tab（全部/教务/系统），列表项点击进入详情
 */

import { router } from '@kit.ArkUI'
import { Announcement } from '../model/Models'
import { ApiService } from '../service/ApiService'

@Entry
@Component
struct MessageCenterPage {
  @State category: string = 'all'
  @State notifications: Announcement[] = []
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadNotifications()
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => { router.back() })
        Text('消息通知').fontSize(18).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
        Text('全部已读').fontSize(14).fontColor('#409EFF')
          .onClick(() => { this.markAllRead() })
      }
      .width('100%').padding(16)

      Row() {
        this.CategoryTab('全部', 'all')
        this.CategoryTab('教务', 'academic')
        this.CategoryTab('系统', 'system')
      }
      .width('100%').padding({ left: 16, right: 16, bottom: 8 })

      List() {
        ForEach(this.filteredNotifications, (item: Announcement) => {
          ListItem() {
            Row() {
              if (item.isTop === 1) {
                Text('置顶').fontSize(10).fontColor('#FF4D4F')
                  .padding({ left: 4, right: 4 }).margin({ right: 8 })
              }
              Column() {
                Text(item.title).fontSize(15).maxLines(1)
                Text(item.summary).fontSize(12).fontColor('#999').maxLines(2).margin({ top: 4 })
                Text(item.publishTime).fontSize(10).fontColor('#CCC').margin({ top: 4 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('90%').padding(12)
            .backgroundColor(Color.White).borderRadius(8)
            .margin({ top: 8, bottom: 4 })
          }
        })
      }
      .width('100%')
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder CategoryTab(label: string, value: string) {
    Text(label)
      .fontSize(14)
      .fontColor(this.category === value ? '#409EFF' : '#666')
      .fontWeight(this.category === value ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .onClick(() => { this.category = value })
  }

  get filteredNotifications(): Announcement[] {
    if (this.category === 'all') return this.notifications
    return this.notifications.filter((n: Announcement) => n.category === this.category)
  }

  async loadNotifications(): Promise<void> {
    this.isLoading = true
    const result = await ApiService.getAnnouncementList('')
    if (result.code === 200 && result.data !== undefined) {
      this.notifications = ApiService.parseAnnouncementList(result.data)
    }
    this.isLoading = false
  }

  markAllRead(): void {
    AlertDialog.show({ message: '已全部标记为已读' })
  }
}
