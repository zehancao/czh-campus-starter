let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('dateStr') dateStr: string = '';
  @LocalStorageProp('semesterWeek') semesterWeek: string = '';
  @LocalStorageProp('courseCount') courseCount: number = 0;
  @LocalStorageProp('nextCourse') nextCourse: string = '';
  @LocalStorageProp('c0_name') c0Name: string = '';
  @LocalStorageProp('c0_room') c0Room: string = '';
  @LocalStorageProp('c0_time') c0Time: string = '';
  @LocalStorageProp('c1_name') c1Name: string = '';
  @LocalStorageProp('c1_room') c1Room: string = '';
  @LocalStorageProp('c1_time') c1Time: string = '';
  @LocalStorageProp('c2_name') c2Name: string = '';
  @LocalStorageProp('c2_room') c2Room: string = '';
  @LocalStorageProp('c2_time') c2Time: string = '';
  @LocalStorageProp('c3_name') c3Name: string = '';
  @LocalStorageProp('c3_room') c3Room: string = '';
  @LocalStorageProp('c3_time') c3Time: string = '';
  @LocalStorageProp('c4_name') c4Name: string = '';
  @LocalStorageProp('c4_room') c4Room: string = '';
  @LocalStorageProp('c4_time') c4Time: string = '';

  build() {
    Column() {
      Row() {
        Text(this.dateStr)
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
        if (this.semesterWeek.length > 0) {
          Text(this.semesterWeek)
            .fontSize(12)
            .fontColor('#4F6EF7')
            .margin({ left: 8 })
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(8)
            .backgroundColor('#EEF0FF')
        }
      }
      .width('100%')
      .margin({ bottom: 4 })

      if (this.courseCount === 0) {
        Column() {
          Text('今天没课 🎉')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 24, bottom: 8 })
          Text('好好休息，劳逸结合')
            .fontSize(12)
            .fontColor('#BBBBBB')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          if (this.c0Name.length > 0) {
            this.CourseRow(this.c0Time, this.c0Name, this.c0Room)
          }
          if (this.c1Name.length > 0) {
            this.CourseRow(this.c1Time, this.c1Name, this.c1Room)
          }
          if (this.c2Name.length > 0) {
            this.CourseRow(this.c2Time, this.c2Name, this.c2Room)
          }
          if (this.c3Name.length > 0) {
            this.CourseRow(this.c3Time, this.c3Name, this.c3Room)
          }
          if (this.c4Name.length > 0) {
            this.CourseRow(this.c4Time, this.c4Name, this.c4Room)
          }
        }
        .width('100%')

        if (this.courseCount > 5) {
          Text(`还有${this.courseCount - 5}节课...`)
            .fontSize(11)
            .fontColor('#999999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 4 })
        }

        if (this.nextCourse.length > 0) {
          Row() {
            Text(this.nextCourse)
              .fontSize(12)
              .fontColor('#4F6EF7')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
          .backgroundColor('#F5F6FF')
          .margin({ top: 4 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .onClick(() => {
      postCardAction(this, {
        'action': 'router',
        'abilityName': 'EntryAbility',
        'params': {
          'targetPage': 'pages/SchedulePage'
        }
      });
    })
  }

  @Builder
  CourseRow(time: string, name: string, room: string) {
    Row() {
      Column() {
        Text(time)
          .fontSize(10)
          .fontColor('#999999')
      }
      .width(80)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Row()
          .width(3)
          .height('100%')
          .backgroundColor('#4F6EF7')
          .borderRadius(2)
      }
      .height(24)

      Blank().width(6)

      Column() {
        Text(name)
          .fontSize(12)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(room.length > 0 ? room : '教室未定')
          .fontSize(10)
          .fontColor('#999999')
          .margin({ top: 1 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 2 })
  }
}
