import { Constants } from '../common/Constants';
import { ApiService, ApiResult } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { router } from '@kit.ArkUI';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const WEEK_DAY_LABELS: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

@Entry
@Component
struct AddCoursePage {
  @State private courseName: string = '';
  @State private classroom: string = '';
  @State private teacherName: string = '';
  @State private dayOfWeek: number = 1;
  @State private startSection: number = 1;
  @State private endSection: number = 2;
  @State private selectedWeeks: boolean[] = [];
  @State private semesterWeekCount: number = 20;
  @State private semesterTitle: string = '';
  @State private showWeekSheet: boolean = false;
  @State private showPeriodSheet: boolean = false;
  @State private showClassroomSheet: boolean = false;
  @State private weekParityMode: string = 'all';
  @State private tempDayIndex: number = 0;
  @State private tempStartIndex: number = 0;
  @State private tempEndIndex: number = 1;
  @State private isSaving: boolean = false;
  @State private buildings: string[] = [];
  @State private roomsInBuilding: string[] = [];
  @State private selectedBuildingIndex: number = 0;
  @State private selectedRoomIndex: number = 0;
  private semesterId: number = 1;

  private makeWeekNumbers(): number[] {
    const arr: number[] = [];
    for (let i = 1; i <= this.semesterWeekCount; i++) {
      arr.push(i);
    }
    return arr;
  }

  private makeSectionLabels(): string[] {
    const arr: string[] = [];
    for (let i = 1; i <= Constants.SECTION_TIMES.length; i++) {
      arr.push(`第${i}节`);
    }
    return arr;
  }

  aboutToAppear(): void {
    const params: Object = this.getUIContext().getRouter().getParams();
    if (params !== null && params !== undefined) {
      const p = params as Record<string, Object>;
      const wc = p['semesterWeekCount'];
      if (wc !== undefined && wc !== null) {
        this.semesterWeekCount = wc as number;
      }
      const st = p['semesterTitle'];
      if (st !== undefined && st !== null) {
        this.semesterTitle = st as string;
      }
      const sid = p['semesterId'];
      if (sid !== undefined && sid !== null) {
        this.semesterId = sid as number;
      }
    }
    const weeks: boolean[] = [];
    for (let i = 0; i < this.semesterWeekCount; i++) {
      weeks.push(true);
    }
    this.selectedWeeks = weeks;
    this.loadBuildings();
  }

  private async loadBuildings(): Promise<void> {
    this.buildings = await ApiService.getBuildings();
  }

  private async loadRooms(building: string): Promise<void> {
    this.roomsInBuilding = await ApiService.getRoomsByBuilding(building);
    this.selectedRoomIndex = 0;
  }

  private computeWeekLabel(): string {
    let first: number = -1;
    let last: number = -1;
    for (let i = 0; i < this.selectedWeeks.length; i++) {
      if (this.selectedWeeks[i]) {
        if (first < 0) {
          first = i;
        }
        last = i;
      }
    }
    if (first < 0) {
      return '请选择周数';
    }
    if (this.weekParityMode === 'odd') {
      return '单周';
    }
    if (this.weekParityMode === 'even') {
      return '双周';
    }
    if (this.weekParityMode === 'all') {
      return `第1-${this.semesterWeekCount}周（全选）`;
    }
    return `第${first + 1}-${last + 1}周`;
  }

  private computePeriodLabel(): string {
    return `${WEEK_DAY_LABELS[this.dayOfWeek - 1]} 第${this.startSection}-${this.endSection}节`;
  }

  private toggleWeek(week: number): void {
    const newW: boolean[] = [];
    for (let i = 0; i < this.selectedWeeks.length; i++) {
      if (i === week - 1) {
        newW.push(!this.selectedWeeks[i]);
      } else {
        newW.push(this.selectedWeeks[i]);
      }
    }
    this.selectedWeeks = newW;
    this.weekParityMode = 'custom';
  }

  private setWeekParity(mode: string): void {
    this.weekParityMode = mode;
    const newW: boolean[] = [];
    for (let i = 0; i < this.semesterWeekCount; i++) {
      if (mode === 'all') {
        newW.push(true);
      } else if (mode === 'odd') {
        newW.push((i + 1) % 2 === 1);
      } else if (mode === 'even') {
        newW.push((i + 1) % 2 === 0);
      } else {
        newW.push(false);
      }
    }
    this.selectedWeeks = newW;
  }

  private openPeriodSheet(): void {
    this.tempDayIndex = this.dayOfWeek - 1;
    this.tempStartIndex = this.startSection - 1;
    this.tempEndIndex = this.endSection - 1;
    this.showPeriodSheet = true;
  }

  private confirmPeriod(): void {
    this.dayOfWeek = this.tempDayIndex + 1;
    this.startSection = this.tempStartIndex + 1;
    this.endSection = this.tempEndIndex + 1;
    this.showPeriodSheet = false;
  }

  private openClassroomSheet(): void {
    if (this.buildings.length === 0) {
      return;
    }
    this.selectedBuildingIndex = 0;
    this.selectedRoomIndex = 0;
    const building: string = this.buildings[0];
    this.loadRooms(building);
    this.showClassroomSheet = true;
  }

  private confirmClassroom(): void {
    if (this.roomsInBuilding.length > 0) {
      this.classroom = this.roomsInBuilding[this.selectedRoomIndex];
    }
    this.showClassroomSheet = false;
  }

  private async saveAndBack(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    if (this.courseName.trim().length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入课程名称' });
      return;
    }
    let first: number = -1;
    let last: number = -1;
    for (let i = 0; i < this.selectedWeeks.length; i++) {
      if (this.selectedWeeks[i]) {
        if (first < 0) {
          first = i;
        }
        last = i;
      }
    }
    if (first < 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请至少选择一周' });
      return;
    }
    let weekParity: string = 'all';
    if (this.weekParityMode === 'odd') {
      weekParity = 'odd';
    } else if (this.weekParityMode === 'even') {
      weekParity = 'even';
    }
    this.isSaving = true;
    const store: AppStore = AppStore.getInstance();
    if (!store.isLoggedIn) {
      this.getUIContext().getPromptAction().showToast({ message: '请先登录' });
      this.isSaving = false;
      return;
    }
    const params: Record<string, Object> = {
      'semesterId': this.semesterId,
      'courseName': this.courseName.trim(),
      'classroom': this.classroom,
      'teacher': this.teacherName.trim(),
      'dayOfWeek': this.dayOfWeek,
      'startSection': this.startSection,
      'endSection': this.endSection,
      'startWeek': first + 1,
      'endWeek': last + 1,
      'remark': weekParity === 'all' ? '' : weekParity === 'odd' ? '单周' : '双周'
    } as Record<string, Object>;
    const result: ApiResult = await ApiService.addPersonalCourse(params);
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '课程已添加' });
      router.back();
    } else {
      this.getUIContext().getPromptAction().showToast({ message: result.msg.length > 0 ? result.msg : '添加失败' });
    }
    this.isSaving = false;
  }

  @Builder
  WeekSheetContent(): void {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor(Theme.textSecondary)
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .onClick(() => {
            this.showWeekSheet = false;
          })
        Blank()
        Text('周数')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.textPrimary)
        Blank()
        Text('完成')
          .fontSize(16)
          .fontColor(Theme.primary)
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .onClick(() => {
            this.showWeekSheet = false;
          })
      }
      .width('100%')

      Row() {
        this.ParityOption('单周', 'odd')
        this.ParityOption('双周', 'even')
        this.ParityOption('全选', 'all')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ top: 14, bottom: 18 })

      Grid() {
        ForEach(this.makeWeekNumbers(), (week: number, idx: number) => {
          GridItem() {
            Text(`${week}`)
              .width('100%')
              .aspectRatio(1)
              .fontSize(14)
              .fontColor(this.selectedWeeks[week - 1] ? Color.White : Theme.textSecondary)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.selectedWeeks[week - 1] ? Theme.primary : Theme.bgInput)
              .borderRadius(8)
          }
          .padding(5)
          .onClick(() => {
            this.toggleWeek(week);
          })
        }, (week: number) => `week_${week}`)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .width('100%')
      .padding({ left: 14, right: 14, bottom: 28 })
    }
    .width('100%')
    .backgroundColor(Theme.bgCard)
    .borderRadius({ topLeft: 28, topRight: 28 })
  }

  @Builder
  PeriodSheetContent(): void {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor(Theme.textSecondary)
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .onClick(() => {
            this.showPeriodSheet = false;
          })
        Blank()
        Text(`${WEEK_DAY_LABELS[this.tempDayIndex]} 第${this.tempStartIndex + 1}-${this.tempEndIndex + 1}节`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.textPrimary)
        Blank()
        Text('完成')
          .fontSize(16)
          .fontColor(Theme.primary)
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .onClick(() => {
            this.confirmPeriod();
          })
      }
      .width('100%')

      Row() {
        TextPicker({ range: WEEK_DAY_LABELS, selected: $$this.tempDayIndex })
          .layoutWeight(3)
        TextPicker({ range: this.makeSectionLabels(), selected: $$this.tempStartIndex })
          .layoutWeight(3)
          .onChange((value: string | string[], index: number | number[]) => {
            if (this.tempEndIndex < this.tempStartIndex) {
              this.tempEndIndex = this.tempStartIndex;
            }
          })
        Text('—')
          .layoutWeight(1)
          .fontSize(18)
          .fontColor(Theme.textSecondary)
          .textAlign(TextAlign.Center)
        TextPicker({ range: this.makeSectionLabels(), selected: $$this.tempEndIndex })
          .layoutWeight(3)
          .onChange((value: string | string[], index: number | number[]) => {
            if (this.tempEndIndex < this.tempStartIndex) {
              this.tempStartIndex = this.tempEndIndex;
            }
          })
      }
      .width('100%')
      .height(200)
      .padding({ left: 8, right: 8, bottom: 24 })
    }
    .width('100%')
    .backgroundColor(Theme.bgCard)
    .borderRadius({ topLeft: 28, topRight: 28 })
  }

  @Builder
  ClassroomSheetContent(): void {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor(Theme.textSecondary)
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .onClick(() => {
            this.showClassroomSheet = false;
          })
        Blank()
        Text('选择教室')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.textPrimary)
        Blank()
        Text('完成')
          .fontSize(16)
          .fontColor(Theme.primary)
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .onClick(() => {
            this.confirmClassroom();
          })
      }
      .width('100%')

      Row() {
        TextPicker({ range: this.buildings, selected: $$this.selectedBuildingIndex })
          .layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            const idx: number = index as number;
            if (idx >= 0 && idx < this.buildings.length) {
              this.loadRooms(this.buildings[idx]);
            }
          })
        TextPicker({ range: this.roomsInBuilding, selected: $$this.selectedRoomIndex })
          .layoutWeight(1)
      }
      .width('100%')
      .height(200)
      .padding({ left: 8, right: 8, bottom: 24 })
    }
    .width('100%')
    .backgroundColor(Theme.bgCard)
    .borderRadius({ topLeft: 28, topRight: 28 })
  }

  build() {
    Column() {
      NavHeader({ title: '添加课程' }) {
        Text(this.isSaving ? '保存中' : '保存')
          .fontSize(14).fontColor(Theme.primary)
          .width(64).height(34).textAlign(TextAlign.Center)
          .backgroundColor(Theme.primaryLight).borderRadius(17)
          .onClick(() => { this.saveAndBack() })
      }

      Scroll() {
        Column() {
          Row() {
            Column() {
              Text('当前学期为')
                .fontSize(Theme.fsSubtitle)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
              Text('返回课程表页面即可切换学期')
                .fontSize(Theme.fsCaption)
                .fontColor(Theme.textTertiary)
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text(this.semesterTitle)
              .fontSize(Theme.fsCaption)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.primary)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(Theme.primaryLight)
              .borderRadius(Theme.chipRadius)
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 16, bottom: 16 })
          .backgroundColor(Theme.bgCard)
          .borderRadius(Theme.cardRadius)
          .margin({ bottom: 16 })
          .shadow(ShadowStyle.nmRaised)

          Column() {
            this.FormInputRow('课程名称', '请输入课程名称', 1)
            this.RowDivider()

            Row() {
              Text('课程周期')
                .fontSize(15)
                .fontColor(Theme.textPrimary)
                .width(80)
              Blank()
              Text(this.computeWeekLabel())
                .fontSize(14)
                .fontColor(Theme.textSecondary)
                .padding({ left: 10, right: 8, top: 5, bottom: 5 })
                .backgroundColor(Theme.bgInput)
                .borderRadius(Theme.chipRadius)
              Text('›')
                .fontSize(22)
                .fontColor(Theme.textDisabled)
                .margin({ left: 6 })
            }
            .width('100%')
            .height(58)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.showWeekSheet = true;
            })
            .bindSheet($$this.showWeekSheet, this.WeekSheetContent(), {
              height: SheetSize.FIT_CONTENT,
              showClose: false,
              onDisappear: () => {
                this.showWeekSheet = false;
              }
            })
            this.RowDivider()

            Row() {
              Text('课程节数')
                .fontSize(15)
                .fontColor(Theme.textPrimary)
                .width(80)
              Blank()
              Text(this.computePeriodLabel())
                .fontSize(14)
                .fontColor(Theme.danger)
                .padding({ left: 10, right: 8, top: 5, bottom: 5 })
                .backgroundColor(Theme.dangerLight)
                .borderRadius(Theme.chipRadius)
              Text('›')
                .fontSize(22)
                .fontColor(Theme.textDisabled)
                .margin({ left: 6 })
            }
            .width('100%')
            .height(58)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.openPeriodSheet();
            })
            .bindSheet($$this.showPeriodSheet, this.PeriodSheetContent(), {
              height: SheetSize.FIT_CONTENT,
              showClose: false,
              onDisappear: () => {
                this.showPeriodSheet = false;
              }
            })
            this.RowDivider()

            Row() {
              Text('选择教室')
                .fontSize(15)
                .fontColor(Theme.textPrimary)
                .width(80)
              Blank()
              Text(this.classroom.length > 0 ? this.classroom : '教学楼+教室号')
                .fontSize(14)
                .fontColor(this.classroom.length > 0 ? Theme.textSecondary : Theme.textDisabled)
                .padding({ left: 10, right: 8, top: 5, bottom: 5 })
                .backgroundColor(Theme.bgInput)
                .borderRadius(Theme.chipRadius)
              Text('›')
                .fontSize(22)
                .fontColor(Theme.textDisabled)
                .margin({ left: 6 })
            }
            .width('100%')
            .height(58)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.openClassroomSheet();
            })
            .bindSheet($$this.showClassroomSheet, this.ClassroomSheetContent(), {
              height: SheetSize.FIT_CONTENT,
              showClose: false,
              onDisappear: () => {
                this.showClassroomSheet = false;
              }
            })
            this.RowDivider()

            this.FormInputRow('手动填写', '操场/体育馆等', 2)
            this.RowDivider()

            this.FormInputRow('任课老师', '请输入任课老师', 3)
          }
          .width('100%')
          .backgroundColor(Theme.bgCard)
          .borderRadius(Theme.cardRadius)
          .shadow(ShadowStyle.nmRaised)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 40 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  FormInputRow(label: string, placeholder: string, fieldType: number): void {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(Theme.textPrimary)
        .width(80)
      TextInput({ placeholder: placeholder })
        .layoutWeight(1)
        .height(40)
        .fontSize(15)
        .fontColor(Theme.textPrimary)
        .placeholderColor(Theme.textDisabled)
        .textAlign(TextAlign.End)
        .backgroundColor(Theme.bgInput)
        .borderRadius(20)
        .padding({ left: 12, right: 12 })
        .onChange((val: string) => {
          if (fieldType === 1) {
            this.courseName = val;
          } else if (fieldType === 2) {
            this.classroom = val;
          } else if (fieldType === 3) {
            this.teacherName = val;
          }
        })
    }
    .width('100%')
    .height(58)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  RowDivider(): void {
    Row()
      .width('100%')
      .height(0.5)
      .margin({ left: 16 })
      .backgroundColor(Theme.border)
  }

  @Builder
  ParityOption(label: string, mode: string): void {
    Row() {
      Stack() {
        Row()
          .width(18)
          .height(18)
          .borderRadius(9)
          .border({ width: 2, color: this.weekParityMode === mode ? Theme.primary : Theme.textDisabled })
        if (this.weekParityMode === mode) {
          Row()
            .width(10)
            .height(10)
            .borderRadius(5)
            .backgroundColor(Theme.primary)
        }
      }
      .width(18)
      .height(18)
      Text(label)
        .fontSize(14)
        .fontColor(this.weekParityMode === mode ? Theme.primary : Theme.textSecondary)
        .margin({ left: 6 })
    }
    .onClick(() => {
      this.setWeekParity(mode);
    })
  }
}
