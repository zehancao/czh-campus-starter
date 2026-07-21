import { AppStore } from '../service/AppStore';
import { CourseSchedule, Semester } from '../model/Models';
import { Constants } from '../common/Constants';
import { ApiService, ApiResult } from '../service/ApiService';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';
import { router } from '@kit.ArkUI';
import { calcSemesterWeek, semesterWeekDate } from '../common/utils';

const WEEK_DAY_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];
const SCHEDULE_SECTION_HEIGHT: number = 66;

@Entry
@Component
struct SchedulePage {
  @State scheduleList: CourseSchedule[] = [];
  @State scheduleGrid: CourseSchedule[][] = [];
  @State currentWeek: number = 1;
  @State todayWeek: number = 1;
  @State semesterId: number = 0;
  @State semesterWeekCount: number = 20;
  @State semesterName: string = '';
  @State semesterStartDate: string = '';
  @State showCourseDetail: boolean = false;
  @State selectedCourse: CourseSchedule = new CourseSchedule();
  @State todayCourses: CourseSchedule[] = [];

  aboutToAppear(): void {
    this.loadSemester();
  }

  private async loadSemester(): Promise<void> {
    const result: ApiResult = await ApiService.getCurrentSemester();
    if (result.code === 200 && result.data !== undefined) {
      const semester: Semester = ApiService.parseSemester(result.data);
      this.semesterId = semester.id;
      this.semesterName = semester.name;
      this.semesterStartDate = semester.startDate;
      this.semesterWeekCount = semester.weekCount;
      this.todayWeek = this.calcCurrentWeek(semester.startDate, semester.weekCount);
      this.currentWeek = this.todayWeek;
    }
    this.loadSchedule();
  }

  private calcCurrentWeek(startDateStr: string, weekCount: number): number {
    return calcSemesterWeek(startDateStr, weekCount);
  }

  private async loadSchedule(): Promise<void> {
    const sid: number = this.semesterId > 0 ? this.semesterId : 1;
    const result: ApiResult = await ApiService.getMySchedule(sid);
    if (result.code === 200) {
      if (result.data !== undefined) {
        this.scheduleList = ApiService.parseScheduleList(result.data);
      } else {
        this.scheduleList = [];
      }
      this.updateScheduleGrid();
    }
  }

  private updateScheduleGrid(): void {
    const today: number = new Date().getDay();
    const dayOfWeek: number = today === 0 ? 7 : today;
    const filtered: CourseSchedule[] = this.scheduleList.filter(
      (item: CourseSchedule) => this.isCourseActiveInWeek(item, this.currentWeek));
    this.todayCourses = filtered.filter((item: CourseSchedule) => item.dayOfWeek === dayOfWeek);
    this.scheduleGrid = [];
    for (let day = 1; day <= 7; day++) {
      const dayList: CourseSchedule[] = [];
      for (let sec = 1; sec <= 10; sec++) {
        const found: CourseSchedule | undefined = filtered.find(
          (item: CourseSchedule) => item.dayOfWeek === day && item.startSection <= sec && item.endSection >= sec);
        dayList.push(found ?? new CourseSchedule());
      }
      this.scheduleGrid.push(dayList);
    }
  }

  private isCourseActiveInWeek(item: CourseSchedule, week: number): boolean {
    if (item.startWeek > week || item.endWeek < week) {
      return false;
    }
    if (item.weekParity === 'odd') {
      return week % 2 === 1;
    }
    if (item.weekParity === 'even') {
      return week % 2 === 0;
    }
    return true;
  }

  private semesterTitle(): string {
    return this.semesterName.length > 0 ? this.semesterName : '当前学期';
  }

  private weekDate(dayIndex: number): Date | null {
    const semesterDate: Date | null = semesterWeekDate(this.semesterStartDate, this.currentWeek, dayIndex);
    if (semesterDate !== null) {
      return semesterDate;
    }
    const parts: string[] = this.semesterStartDate.split('-');
    if (parts.length < 3) {
      return null;
    }
    const date: Date = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
    const dow: number = date.getDay();
    const offsetToMonday: number = dow === 0 ? -6 : 1 - dow;
    date.setDate(date.getDate() + offsetToMonday + (this.currentWeek - 1) * 7 + dayIndex);
    return date;
  }

  private weekMonthText(): string {
    const date: Date | null = this.weekDate(0);
    if (date === null) {
      return '';
    }
    return `${date.getMonth() + 1}月`;
  }

  private weekDayText(dayIndex: number): string {
    const date: Date | null = this.weekDate(dayIndex);
    if (date === null) {
      return `${dayIndex + 1}`;
    }
    return `${date.getDate()}`;
  }

  private courseAtStart(day: number, section: number): CourseSchedule {
    for (let i = 0; i < this.scheduleList.length; i++) {
      const item: CourseSchedule = this.scheduleList[i];
      if (item.dayOfWeek === day && item.startSection === section && this.isCourseActiveInWeek(item, this.currentWeek)) {
        return item;
      }
    }
    return new CourseSchedule();
  }

  private hasCourseCovering(day: number, section: number): boolean {
    for (let i = 0; i < this.scheduleList.length; i++) {
      const item: CourseSchedule = this.scheduleList[i];
      if (item.dayOfWeek === day && item.startSection < section && item.endSection >= section && this.isCourseActiveInWeek(item, this.currentWeek)) {
        return true;
      }
    }
    return false;
  }

  private courseDuration(item: CourseSchedule): number {
    const duration: number = item.endSection - item.startSection + 1;
    return duration > 0 ? duration : 1;
  }

  private courseBg(item: CourseSchedule): string {
    if (item.source === 'personal') {
      return Theme.personalCardBg[Math.abs(item.colorIndex) % Theme.personalCardBg.length];
    }
    return Theme.scheduleCardBg[Math.abs(item.colorIndex) % Theme.scheduleCardBg.length];
  }

  private courseFg(item: CourseSchedule): string {
    if (item.source === 'personal') {
      return Theme.personalCardFg[Math.abs(item.colorIndex) % Theme.personalCardFg.length];
    }
    return Theme.scheduleCardFg[Math.abs(item.colorIndex) % Theme.scheduleCardFg.length];
  }

  private sectionStartTime(section: number): string {
    if (section >= 1 && section <= Constants.SECTION_TIMES.length) {
      return Constants.SECTION_TIMES[section - 1][0];
    }
    return '';
  }

  private sectionEndTime(section: number): string {
    if (section >= 1 && section <= Constants.SECTION_TIMES.length) {
      return Constants.SECTION_TIMES[section - 1][1];
    }
    return '';
  }

  private courseTimeText(item: CourseSchedule): string {
    return `${this.sectionStartTime(item.startSection)}-${this.sectionEndTime(item.endSection)}`;
  }

  private courseWeekText(item: CourseSchedule): string {
    let text: string = `第${item.startWeek}-${item.endWeek}周`;
    if (item.weekParity === 'odd') {
      text += ' 单周';
    }
    if (item.weekParity === 'even') {
      text += ' 双周';
    }
    return text;
  }

  private courseBriefText(item: CourseSchedule): string {
    const room: string = item.classroom.length > 0 ? item.classroom : '教室未填';
    if (item.teacherName.length > 0) {
      return `${item.courseName} @${room}\n${item.teacherName}`;
    }
    return `${item.courseName} @${room}`;
  }

  private showWeekPicker(): void {
    const weeks: string[] = [];
    for (let i = 1; i <= this.semesterWeekCount; i++) {
      weeks.push(`第${i}周`);
    }
    let currentIdx: number = this.currentWeek - 1;
    TextPickerDialog.show({
      range: weeks,
      selected: currentIdx,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < weeks.length) {
          this.currentWeek = idx + 1;
          this.updateScheduleGrid();
        }
      }
    });
  }

  private backToCurrentWeek(): void {
    this.currentWeek = this.todayWeek;
    this.updateScheduleGrid();
  }

  private openCourseDetail(item: CourseSchedule): void {
    this.selectedCourse = item;
    this.showCourseDetail = true;
  }

  private closeCourseDetail(): void {
    this.showCourseDetail = false;
    this.selectedCourse = new CourseSchedule();
  }

  build() {
    Column() {
      NavHeader({ title: '我的课表' })

      Stack() {
        Column() {
          this.ScheduleHeader()
          this.ScheduleWeekHeader()
          this.ScheduleGrid()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.bgPage)

        if (this.currentWeek !== this.todayWeek) {
          Button('切回本周')
            .width(88)
            .height(42)
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor(Theme.primary)
            .borderRadius(24)
            .padding({ left: 24, right: 24 })
            .shadow(ShadowStyle.sm)
            .position({ x: 292, y: 610 })
            .onClick(() => {
              this.backToCurrentWeek();
            })
        }

        if (this.showCourseDetail) {
          this.CourseDetailOverlay()
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  ScheduleHeader() {
    Row() {
      Column() {
        Row() {
          Text(`第${this.currentWeek}周`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textPrimary)
          Text('▼')
            .fontSize(16)
            .fontColor(Theme.primary)
            .margin({ left: 8 })
        }
        .onClick(() => {
          this.showWeekPicker();
        })
        Text(this.semesterTitle())
          .fontSize(14)
          .fontColor(Theme.textTertiary)
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('+')
        .fontSize(28)
        .fontColor(Theme.primary)
        .fontWeight(FontWeight.Bold)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(Theme.primaryLight)
        .borderRadius(21)
        .shadow(ShadowStyle.sm)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/AddCoursePage',
            params: {
              semesterWeekCount: this.semesterWeekCount,
              semesterTitle: this.semesterTitle()
            }
          }).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: '打开添课页失败' });
          });
        })
    }
    .width('100%')
    .height(62)
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
    .backgroundColor(Theme.bgCard)
    .borderRadius(Theme.cardRadius)
    .shadow(ShadowStyle.nmRaised)
    .margin({ left: 12, right: 12, top: 8, bottom: 8 })
  }

  @Builder
  ScheduleWeekHeader() {
    Row() {
      Column() {
        Text(this.weekMonthText().length > 0 ? this.weekMonthText().replace('月', '') : '')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
        Text('月')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
          .margin({ top: 2 })
      }
      .width(50)
      .alignItems(HorizontalAlign.Center)

      ForEach(WEEK_DAY_LABELS, (day: string, index: number) => {
        Column() {
          Text(day)
            .fontSize(19)
            .fontColor(Theme.textPrimary)
          Text(this.weekDayText(index))
            .fontSize(15)
            .fontColor(Theme.textTertiary)
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .height(58)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }, (day: string, index: number) => `${index}-${day}`)
    }
    .width('100%')
    .height(60)
    .backgroundColor(Theme.bgCard)
    .borderRadius(18)
    .shadow(ShadowStyle.sm)
    .margin({ left: 8, right: 8, bottom: 6 })
  }

  @Builder
  ScheduleGrid() {
    Scroll() {
      Row() {
        Column() {
          ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (section: number) => {
            Column() {
              Text(`${section}`)
                .fontSize(18)
                .fontColor(Theme.textPrimary)
              Text(this.sectionStartTime(section))
                .fontSize(11)
                .fontColor(Theme.textTertiary)
                .margin({ top: 3 })
              Text(this.sectionEndTime(section))
                .fontSize(11)
                .fontColor(Theme.textTertiary)
                .margin({ top: 1 })
            }
            .width(50)
            .height(SCHEDULE_SECTION_HEIGHT)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }, (section: number) => `${section}`)
        }
        .width(50)

        Row() {
          ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
            Column() {
              ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (section: number) => {
                Stack() {
                  Divider()
                    .height(1)
                    .color(Theme.border)
                    .width('100%')
                    .position({ x: 0, y: SCHEDULE_SECTION_HEIGHT - 1 })
                  if (!this.hasCourseCovering(day, section)) {
                    this.ScheduleCell(day, section)
                  }
                }
                .width('100%')
                .height(SCHEDULE_SECTION_HEIGHT)
              }, (section: number) => `${day}-${section}`)
            }
            .layoutWeight(1)
          }, (day: number) => `${day}`)
        }
        .layoutWeight(1)
        .padding({ right: 6 })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .backgroundColor(Theme.bgCard)
    .borderRadius(18)
    .margin({ left: 8, right: 8, bottom: 8 })
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  ScheduleCell(day: number, section: number) {
    Column() {
      if (this.courseAtStart(day, section).courseName.length > 0) {
        this.ScheduleCourseCard(this.courseAtStart(day, section))
      }
    }
    .width('100%')
    .height(SCHEDULE_SECTION_HEIGHT)
  }

  @Builder
  ScheduleCourseCard(item: CourseSchedule) {
    Column() {
      Text(this.courseBriefText(item))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.courseFg(item))
        .lineHeight(18)
        .maxLines(this.courseDuration(item) <= 1 ? 2 : 5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('92%')
    .height(this.courseDuration(item) * SCHEDULE_SECTION_HEIGHT - 8)
    .padding({ left: 7, right: 5, top: 8, bottom: 6 })
    .backgroundColor(this.courseBg(item))
    .borderRadius(8)
    .shadow(ShadowStyle.sm)
    .margin({ left: 3, right: 3, top: 4 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.openCourseDetail(item);
    })
  }

  @Builder
  CourseDetailOverlay() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255,255,255,0.87)')
        .onClick(() => {
          this.closeCourseDetail();
        })

      Column() {
        this.CourseDetailCard(this.selectedCourse, false)
        if (this.selectedCourse.weekParity !== 'all') {
          this.CourseDetailCard(this.selectedCourse, true)
        }
      }
      .width('90%')
      .position({ x: 20, y: 200 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CourseDetailCard(item: CourseSchedule, parityCard: boolean) {
    Column() {
      Row() {
        if (parityCard) {
          Text('非本周')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(Theme.textPrimary)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 8 })
        }
        Text(item.courseName.length > 0 ? item.courseName : '课程名称未录入')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textPrimary)
          .layoutWeight(1)
        if (item.source === 'personal') {
          Text('个人')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(Theme.danger)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 4 })
        }
        if (item.source === 'personal') {
          Text('删除')
            .fontSize(15)
            .fontColor(Theme.danger)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(Color.White)
            .borderRadius(5)
            .onClick(async () => {
              const result: ApiResult = await ApiService.deletePersonalCourse(item.id);
              if (result.code === 200) {
                this.getUIContext().getPromptAction().showToast({ message: '已删除' });
                this.showCourseDetail = false;
                this.loadSchedule();
              } else {
                this.getUIContext().getPromptAction().showToast({ message: result.msg.length > 0 ? result.msg : '删除失败' });
              }
            })
        } else {
          Text('编辑')
            .fontSize(15)
            .fontColor(Theme.textTertiary)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(Color.White)
            .borderRadius(5)
        }
      }
      .width('100%')

      Text(this.courseWeekText(item))
        .fontSize(17)
        .fontColor(Theme.textPrimary)
        .width('100%')
        .margin({ top: 18 })
      Text(`周${WEEK_DAY_LABELS[item.dayOfWeek - 1]} | 第${item.startSection}-${item.endSection}节 | ${this.courseTimeText(item)}`)
        .fontSize(15)
        .fontColor(Theme.textTertiary)
        .width('100%')
        .margin({ top: 12 })
      Text(`教室：${item.classroom.length > 0 ? item.classroom : '未填写'}`)
        .fontSize(15)
        .fontColor(Theme.textTertiary)
        .width('100%')
        .margin({ top: 12 })
      Text(`老师：${item.teacherName.length > 0 ? item.teacherName : '未填写'}`)
        .fontSize(15)
        .fontColor(Theme.textTertiary)
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Theme.bgCard)
    .borderRadius(Theme.cardRadius)
    .shadow(ShadowStyle.nmRaisedLg)
    .margin({ bottom: 18 })
    .alignItems(HorizontalAlign.Start)
  }
}
