import { ApiService } from '../service/ApiService';
import { CourseSchedule } from '../model/Models';
import { Constants } from '../common/Constants';

const ROOM_DAY_LABELS: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

@Entry
@Component
struct RoomSchedulePage {
  @State private classroom: string = '';
  @State private selectedDayOfWeek: number = 1;
  @State private schedules: CourseSchedule[] = [];
  @State private isLoading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.readParams();
    this.loadSchedule();
  }

  private readParams(): void {
    const paramsObj: Object | undefined = this.getUIContext().getRouter().getParams();
    if (paramsObj === undefined || paramsObj === null) {
      return;
    }
    const params: Record<string, Object> = paramsObj as Record<string, Object>;
    const classroomObj: Object = params['classroom'];
    if (classroomObj !== null && classroomObj !== undefined) {
      this.classroom = classroomObj as string;
    }
    const dayObj: Object = params['dayOfWeek'];
    if (dayObj !== null && dayObj !== undefined) {
      if (typeof dayObj === 'number') {
        const dayNum: number = dayObj as number;
        if (dayNum >= 1 && dayNum <= 7) {
          this.selectedDayOfWeek = dayNum;
        }
      } else {
        const parsed: number = parseInt(dayObj as string);
        if (parsed >= 1 && parsed <= 7) {
          this.selectedDayOfWeek = parsed;
        }
      }
    }
  }

  private async loadSchedule(): Promise<void> {
    if (this.classroom.length === 0) {
      this.errorMessage = '教室参数错误';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    this.schedules = [];
    try {
      const list: CourseSchedule[] = await ApiService.getRoomSchedule(this.classroom, this.selectedDayOfWeek);
      this.schedules = this.sortSchedules(list);
    } catch (_err) {
      this.schedules = [];
      this.errorMessage = '课表加载失败，请检查网络或后端服务';
    } finally {
      this.isLoading = false;
    }
  }

  private sortSchedules(list: CourseSchedule[]): CourseSchedule[] {
    const copied: CourseSchedule[] = [];
    for (let i = 0; i < list.length; i++) {
      copied.push(list[i]);
    }
    copied.sort((a: CourseSchedule, b: CourseSchedule) => {
      return a.startSection - b.startSection;
    });
    return copied;
  }

  private dayText(): string {
    return ROOM_DAY_LABELS[this.selectedDayOfWeek - 1];
  }

  private sectionRangeText(item: CourseSchedule): string {
    return `第${item.startSection}-${item.endSection}节`;
  }

  private timeRangeText(item: CourseSchedule): string {
    const startIndex: number = item.startSection - 1;
    const endIndex: number = item.endSection - 1;
    if (startIndex >= 0 && endIndex >= 0 && startIndex < Constants.SECTION_TIMES.length && endIndex < Constants.SECTION_TIMES.length) {
      return `${Constants.SECTION_TIMES[startIndex][0]}-${Constants.SECTION_TIMES[endIndex][1]}`;
    }
    return '';
  }

  private weekText(item: CourseSchedule): string {
    let text: string = `第${item.startWeek}-${item.endWeek}周`;
    if (item.weekParity === 'odd') {
      text += ' 单周';
    }
    if (item.weekParity === 'even') {
      text += ' 双周';
    }
    return text;
  }

  private teacherText(item: CourseSchedule): string {
    return item.teacherName.length > 0 ? item.teacherName : '教师未录入';
  }

  private showDayPicker(): void {
    let currentIdx: number = this.selectedDayOfWeek - 1;
    TextPickerDialog.show({
      range: ROOM_DAY_LABELS,
      selected: currentIdx,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < ROOM_DAY_LABELS.length) {
          this.selectedDayOfWeek = idx + 1;
          this.loadSchedule();
        }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor('#333333')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Column() {
          Text(this.classroom.length > 0 ? this.classroom : '教室课表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
          Text('教室课表')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.dayText())
          .fontSize(14)
          .fontColor('#4A90D9')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#EBF3FC')
          .borderRadius(15)
          .onClick(() => {
            this.showDayPicker();
          })
      }
      .width('100%')
      .height(64)
      .padding({ left: 8, right: 16 })
      .backgroundColor(Color.White)

      Column() {
        Row() {
          Text(this.dayText())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#222222')
          Blank()
          Text(`共 ${this.schedules.length} 节课`)
            .fontSize(13)
            .fontColor('#999999')
        }
        .width('100%')

        Text('点击右上角星期可切换查看其它日期')
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .margin({ top: 6 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .margin({ top: 10 })

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor('#E74C3C')
          .width('100%')
          .padding({ left: 16, right: 16, top: 10 })
      }

      if (this.isLoading && this.schedules.length === 0) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color('#4A90D9')
          Text('正在加载教室课表')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.schedules.length === 0) {
        Column() {
          Text('这一天没有课程安排')
            .fontSize(16)
            .fontColor('#666666')
          Text('该教室当天可以灵活使用')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.schedules, (item: CourseSchedule, index: number) => {
            ListItem() {
              this.CourseCard(item)
            }
          }, (item: CourseSchedule, index: number) => `${index}-${item.courseName}-${item.startSection}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 14, bottom: 20 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  CourseCard(item: CourseSchedule) {
    Row() {
      Column() {
        Text(this.sectionRangeText(item))
          .fontSize(14)
          .fontColor('#4A90D9')
          .fontWeight(FontWeight.Medium)
        Text(this.timeRangeText(item))
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 5 })
      }
      .width(78)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(item.courseName.length > 0 ? item.courseName : '课程名称未录入')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(this.teacherText(item))
            .fontSize(13)
            .fontColor('#666666')
          Text(this.weekText(item))
            .fontSize(13)
            .fontColor('#999999')
            .margin({ left: 12 })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(10)
  }
}
