/**
 * 添加课程页
 * 课程周期：周数方格选择（单周/双周/全选 + 逐格点选）
 * 课程节数：三栏滚动选择（周几 ｜ 开始节 — 结束节）
 */

import { Constants } from '../common/Constants';
import { router } from '@kit.ArkUI';

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
  @State private weekParityMode: string = 'all';
  @State private tempDayIndex: number = 0;
  @State private tempStartIndex: number = 0;
  @State private tempEndIndex: number = 1;

  // ---- 工具：生成周数数组 ----
  private makeWeekNumbers(): number[] {
    const arr: number[] = [];
    for (let i = 1; i <= this.semesterWeekCount; i++) {
      arr.push(i);
    }
    return arr;
  }

  // ---- 工具：生成节数标签数组 ----
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
    }
    const weeks: boolean[] = [];
    for (let i = 0; i < this.semesterWeekCount; i++) {
      weeks.push(true);
    }
    this.selectedWeeks = weeks;
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

  private saveAndBack(): void {
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
    AppStorage.SetOrCreate<boolean>('pending_hasManualCourse', true);
    AppStorage.SetOrCreate<string>('pending_courseName', this.courseName.trim());
    AppStorage.SetOrCreate<string>('pending_classroom', this.classroom.trim());
    AppStorage.SetOrCreate<string>('pending_teacherName', this.teacherName.trim());
    AppStorage.SetOrCreate<number>('pending_dayOfWeek', this.dayOfWeek);
    AppStorage.SetOrCreate<number>('pending_startSection', this.startSection);
    AppStorage.SetOrCreate<number>('pending_endSection', this.endSection);
    AppStorage.SetOrCreate<number>('pending_startWeek', first + 1);
    AppStorage.SetOrCreate<number>('pending_endWeek', last + 1);
    AppStorage.SetOrCreate<string>('pending_weekParity', weekParity);
    router.back();
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('<')
            .fontSize(28)
            .fontColor('#20242A')
            .width(50)
            .height(50)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              router.back();
            })
          Text('添加课程')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#222222')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('保存')
            .fontSize(16)
            .fontColor('#5A82D9')
            .width(50)
            .textAlign(TextAlign.End)
            .onClick(() => {
              this.saveAndBack();
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 6, right: 18 })
        .backgroundColor(Color.White)

        Scroll() {
          Column() {
            // 学期提示卡
            Row() {
              Column() {
                Text('当前学期为')
                  .fontSize(16)
                  .fontColor('#3D6FB8')
                Text('返回课程表页面即可切换学期')
                  .fontSize(13)
                  .fontColor('#3D6FB8')
                  .margin({ top: 8 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text(this.semesterTitle)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#3D6FB8')
            }
            .width('100%')
            .padding(18)
            .backgroundColor('#F1F7FF')
            .borderRadius(10)
            .margin({ bottom: 16 })

            // 表单卡
            Column() {
              this.FormInputRow('课程名称', '请输入课程名称', 1)
              this.RowDivider()
              this.FormSelectRow('课程周期', this.computeWeekLabel(), false, () => {
                this.showWeekSheet = true;
              })
              this.RowDivider()
              this.FormSelectRow('课程节数', this.computePeriodLabel(), true, () => {
                this.openPeriodSheet();
              })
              this.RowDivider()
              this.FormInputRow('教室地点', '请输入教室地点', 2)
              this.RowDivider()
              this.FormInputRow('任课老师', '请输入任课老师', 3)
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(12)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')

      // 周数选择底部弹窗
      if (this.showWeekSheet) {
        Stack() {
          // 遮罩
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => {
              this.showWeekSheet = false;
            })
          // 弹窗内容
          Column() {
            Row() {
              Text('取消')
                .fontSize(16)
                .fontColor('#888888')
                .padding({ left: 20, right: 20, top: 14, bottom: 14 })
                .onClick(() => {
                  this.showWeekSheet = false;
                })
              Blank()
              Text('周数')
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
              Blank()
              Text('完成')
                .fontSize(16)
                .fontColor('#5A82D9')
                .padding({ left: 20, right: 20, top: 14, bottom: 14 })
                .onClick(() => {
                  this.showWeekSheet = false;
                })
            }
            .width('100%')

            // 单周/双周/全选
            Row() {
              this.ParityOption('单周', 'odd')
              this.ParityOption('双周', 'even')
              this.ParityOption('全选', 'all')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .padding({ top: 14, bottom: 18 })

            // 周数方格
            Grid() {
              ForEach(this.makeWeekNumbers(), (week: number, idx: number) => {
                GridItem() {
                  Text(`${week}`)
                    .width('100%')
                    .aspectRatio(1)
                    .fontSize(14)
                    .fontColor(this.selectedWeeks[week - 1] ? Color.White : '#555555')
                    .textAlign(TextAlign.Center)
                    .backgroundColor(this.selectedWeeks[week - 1] ? '#5A82D9' : '#F2F3F5')
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
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 20, topRight: 20 })
          .position({ x: 0, y: '100%' })
          .translate({ y: '-100%' })
        }
        .width('100%')
        .height('100%')
      }

      // 节数选择底部弹窗
      if (this.showPeriodSheet) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => {
              this.showPeriodSheet = false;
            })
          Column() {
            Row() {
              Text('取消')
                .fontSize(16)
                .fontColor('#888888')
                .padding({ left: 20, right: 20, top: 14, bottom: 14 })
                .onClick(() => {
                  this.showPeriodSheet = false;
                })
              Blank()
              Text(`${WEEK_DAY_LABELS[this.tempDayIndex]} 第${this.tempStartIndex + 1}-${this.tempEndIndex + 1}节`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
              Blank()
              Text('完成')
                .fontSize(16)
                .fontColor('#5A82D9')
                .padding({ left: 20, right: 20, top: 14, bottom: 14 })
                .onClick(() => {
                  this.confirmPeriod();
                })
            }
            .width('100%')

            Row() {
              TextPicker({ range: WEEK_DAY_LABELS, selected: this.tempDayIndex })
                .layoutWeight(3)
                .onChange((value: string | string[], index: number | number[]) => {
                  this.tempDayIndex = index as number;
                })
              TextPicker({ range: this.makeSectionLabels(), selected: this.tempStartIndex })
                .layoutWeight(3)
                .onChange((value: string | string[], index: number | number[]) => {
                  this.tempStartIndex = index as number;
                  if (this.tempEndIndex < this.tempStartIndex) {
                    this.tempEndIndex = this.tempStartIndex;
                  }
                })
              Text('—')
                .layoutWeight(1)
                .fontSize(18)
                .fontColor('#666')
                .textAlign(TextAlign.Center)
              TextPicker({ range: this.makeSectionLabels(), selected: this.tempEndIndex })
                .layoutWeight(3)
                .onChange((value: string | string[], index: number | number[]) => {
                  this.tempEndIndex = index as number;
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
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 20, topRight: 20 })
          .position({ x: 0, y: '100%' })
          .translate({ y: '-100%' })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FormInputRow(label: string, placeholder: string, fieldType: number) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .width(80)
      TextInput({ placeholder: placeholder })
        .layoutWeight(1)
        .height(44)
        .fontSize(15)
        .fontColor('#1A1A1A')
        .placeholderColor('#CCCCCC')
        .textAlign(TextAlign.End)
        .backgroundColor(Color.Transparent)
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
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  FormSelectRow(label: string, value: string, isHighlight: boolean, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .width(80)
      Blank()
      Text(value)
        .fontSize(14)
        .fontColor(isHighlight ? '#E74C3C' : '#666666')
      Text('›')
        .fontSize(22)
        .fontColor('#C0C0C0')
        .margin({ left: 6 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(onTap)
  }

  @Builder
  RowDivider() {
    Row()
      .width('100%')
      .height(0.5)
      .margin({ left: 16 })
      .backgroundColor('#F0F0F0')
  }

  @Builder
  ParityOption(label: string, mode: string) {
    Row() {
      Stack() {
        Row()
          .width(18)
          .height(18)
          .borderRadius(9)
          .border({ width: 2, color: this.weekParityMode === mode ? '#5A82D9' : '#CCCCCC' })
        if (this.weekParityMode === mode) {
          Row()
            .width(10)
            .height(10)
            .borderRadius(5)
            .backgroundColor('#5A82D9')
        }
      }
      .width(18)
      .height(18)
      Text(label)
        .fontSize(14)
        .fontColor(this.weekParityMode === mode ? '#5A82D9' : '#666666')
        .margin({ left: 6 })
    }
    .onClick(() => {
      this.setWeekParity(mode);
    })
  }
}
