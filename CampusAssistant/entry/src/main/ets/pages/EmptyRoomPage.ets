import { ApiResult, ApiService } from '../service/ApiService';
import { EmptyRoom, Semester } from '../model/Models';
import { Constants } from '../common/Constants';
import { calcSemesterWeek } from '../common/utils';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

const DAY_LABELS: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const WEEK_LABELS: string[] = [
  '不限周次', '第1周', '第2周', '第3周', '第4周', '第5周', '第6周', '第7周', '第8周', '第9周',
  '第10周', '第11周', '第12周', '第13周', '第14周', '第15周', '第16周', '第17周', '第18周', '第19周', '第20周'
];

@Entry
@Component
struct EmptyRoomPage {
  @State private buildings: string[] = [];
  @State private selectedBuilding: string = '';
  @State private selectedDayOfWeek: number = 1;
  @State private selectedStartSection: number = 1;
  @State private selectedEndSection: number = 2;
  @State private selectedWeek: number = 0;
  @State private rooms: EmptyRoom[] = [];
  @State private isLoading: boolean = false;
  @State private hasSearched: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.initPage();
  }

  private async initPage(): Promise<void> {
    this.selectedDayOfWeek = this.todayDayOfWeek();
    await this.loadCurrentWeek();
    await this.loadBuildings();
    await this.searchRooms();
  }

  private todayDayOfWeek(): number {
    const day: number = new Date().getDay();
    return day === 0 ? 7 : day;
  }

  private async loadBuildings(): Promise<void> {
    try {
      this.buildings = await ApiService.getBuildings();
    } catch (_err) {
      this.buildings = [];
    }
  }

  private async loadCurrentWeek(): Promise<void> {
    try {
      const result: ApiResult = await ApiService.getCurrentSemester();
      if (result.code === 200 && result.data !== undefined) {
        const semester: Semester = ApiService.parseSemester(result.data);
        this.selectedWeek = calcSemesterWeek(semester.startDate, semester.weekCount);
        return;
      }
    } catch (_err) {
    }
    this.selectedWeek = 1;
  }

  private sectionText(section: number): string {
    if (section >= 1 && section <= Constants.SECTION_TIMES.length) {
      const time: string[] = Constants.SECTION_TIMES[section - 1];
      return `第${section}节 ${time[0]}-${time[1]}`;
    }
    return `第${section}节`;
  }

  private selectedBuildingText(): string {
    return this.selectedBuilding.length > 0 ? this.selectedBuilding : '全部教学楼';
  }

  private selectedDayText(): string {
    return DAY_LABELS[this.selectedDayOfWeek - 1];
  }

  private selectedWeekText(): string {
    return this.selectedWeek > 0 ? `第${this.selectedWeek}周` : '不限周次';
  }

  private sectionRangeText(): string {
    if (this.selectedStartSection === this.selectedEndSection) {
      return this.sectionText(this.selectedStartSection);
    }
    return `第${this.selectedStartSection}-${this.selectedEndSection}节`;
  }

  private filterValueText(type: number): string {
    if (type === 1) {
      return this.selectedBuildingText();
    }
    if (type === 2) {
      return this.selectedDayText();
    }
    if (type === 3) {
      return this.sectionText(this.selectedStartSection);
    }
    if (type === 4) {
      return this.sectionText(this.selectedEndSection);
    }
    if (type === 5) {
      return this.selectedWeekText();
    }
    return '';
  }

  private projectorText(room: EmptyRoom): string {
    return room.hasProjector === 1 ? '有投影' : '无投影';
  }

  private acText(room: EmptyRoom): string {
    return room.hasAc === 1 ? '有空调' : '无空调';
  }

  private roomTitle(room: EmptyRoom): string {
    return room.roomNo;
  }

  private roomKey(room: EmptyRoom): string {
    if (room.id > 0) {
      return `${room.id}`;
    }
    return `${room.building}-${room.roomNo}`;
  }

  private resetSearchResult(): void {
    this.rooms = [];
    this.hasSearched = false;
    this.errorMessage = '';
  }

  private async searchRooms(): Promise<void> {
    if (this.selectedDayOfWeek <= 0 || this.selectedStartSection <= 0 || this.selectedEndSection <= 0) {
      this.errorMessage = '请选择星期和节次';
      return;
    }
    if (this.selectedEndSection < this.selectedStartSection) {
      this.errorMessage = '结束节次不能早于开始节次';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    this.hasSearched = true;
    this.rooms = [];
    try {
      let result: EmptyRoom[] = await ApiService.getEmptyRooms(
        this.selectedBuilding,
        this.selectedDayOfWeek,
        this.selectedStartSection,
        this.selectedWeek
      );
      for (let section = this.selectedStartSection + 1; section <= this.selectedEndSection; section++) {
        const sectionRooms: EmptyRoom[] = await ApiService.getEmptyRooms(
          this.selectedBuilding,
          this.selectedDayOfWeek,
          section,
          this.selectedWeek
        );
        const keys: string[] = [];
        for (let i = 0; i < sectionRooms.length; i++) {
          keys.push(this.roomKey(sectionRooms[i]));
        }
        const next: EmptyRoom[] = [];
        for (let i = 0; i < result.length; i++) {
          if (keys.indexOf(this.roomKey(result[i])) >= 0) {
            next.push(result[i]);
          }
        }
        result = next;
        if (result.length === 0) {
          break;
        }
      }
      this.rooms = result;
    } catch (_err) {
      this.rooms = [];
      this.errorMessage = '空教室加载失败，请检查网络或后端服务';
    } finally {
      this.isLoading = false;
    }
  }

  private showBuildingPicker(): void {
    const options: string[] = ['全部教学楼'];
    for (let i = 0; i < this.buildings.length; i++) {
      options.push(this.buildings[i]);
    }
    let currentIdx: number = this.selectedBuilding.length > 0 ? options.indexOf(this.selectedBuilding) : 0;
    if (currentIdx < 0) {
      currentIdx = 0;
    }
    TextPickerDialog.show({
      range: options,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.selectedBuilding = idx === 0 ? '' : options[idx];
          this.resetSearchResult();
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.selectedBuilding = idx === 0 ? '' : options[idx];
          this.resetSearchResult();
        }
      }
    });
  }

  private showDayPicker(): void {
    let currentIdx: number = this.selectedDayOfWeek - 1;
    TextPickerDialog.show({
      range: DAY_LABELS,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < DAY_LABELS.length) {
          this.selectedDayOfWeek = idx + 1;
          this.resetSearchResult();
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < DAY_LABELS.length) {
          this.selectedDayOfWeek = idx + 1;
          this.resetSearchResult();
        }
      }
    });
  }

  private showStartSectionPicker(): void {
    const options: string[] = [];
    for (let i = 1; i <= Constants.SECTION_TIMES.length; i++) {
      options.push(this.sectionText(i));
    }
    let currentIdx: number = this.selectedStartSection - 1;
    TextPickerDialog.show({
      range: options,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.selectedStartSection = idx + 1;
          if (this.selectedEndSection < this.selectedStartSection) {
            this.selectedEndSection = this.selectedStartSection;
          }
          this.resetSearchResult();
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.selectedStartSection = idx + 1;
          if (this.selectedEndSection < this.selectedStartSection) {
            this.selectedEndSection = this.selectedStartSection;
          }
          this.resetSearchResult();
        }
      }
    });
  }

  private showEndSectionPicker(): void {
    const options: string[] = [];
    for (let i = 1; i <= Constants.SECTION_TIMES.length; i++) {
      options.push(this.sectionText(i));
    }
    let currentIdx: number = this.selectedEndSection - 1;
    TextPickerDialog.show({
      range: options,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.selectedEndSection = idx + 1;
          if (this.selectedEndSection < this.selectedStartSection) {
            this.selectedStartSection = this.selectedEndSection;
          }
          this.resetSearchResult();
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.selectedEndSection = idx + 1;
          if (this.selectedEndSection < this.selectedStartSection) {
            this.selectedStartSection = this.selectedEndSection;
          }
          this.resetSearchResult();
        }
      }
    });
  }

  private showWeekPicker(): void {
    let currentIdx: number = this.selectedWeek;
    TextPickerDialog.show({
      range: WEEK_LABELS,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < WEEK_LABELS.length) {
          this.selectedWeek = idx;
          this.resetSearchResult();
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < WEEK_LABELS.length) {
          this.selectedWeek = idx;
          this.resetSearchResult();
        }
      }
    });
  }

  private goSchedule(room: EmptyRoom): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RoomSchedulePage',
      params: {
        'classroom': this.roomTitle(room),
        'dayOfWeek': `${this.selectedDayOfWeek}`
      } as Record<string, string>
    });
  }

  build() {
    Column() {
      NavHeader({ title: '空教室查询' })

      Column() {
        Row() {
          Text('查找空教室')
            .fontSize(Theme.fsTitle)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.textPrimary)
          Blank()
          Text(this.selectedWeekText())
            .fontSize(Theme.fsCaption)
            .fontColor(Theme.primary)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(Theme.primaryLight)
            .borderRadius(Theme.chipRadius)
        }
        .width('100%')
        .margin({ bottom: 12 })

        Row({ space: 8 }) {
          this.FilterItem('教学楼', 1)
          this.FilterItem('星期', 2)
        }
        .width('100%')

        Row({ space: 8 }) {
          this.FilterItem('开始节次', 3)
          this.FilterItem('结束节次', 4)
        }
        .width('100%')
        .margin({ top: 8 })

        Row({ space: 8 }) {
          this.FilterItem('周次', 5)
        }
        .width('100%')
        .margin({ top: 8 })

        Button(this.isLoading ? '查询中...' : '查询空教室')
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor(Theme.primary)
          .borderRadius(Theme.radiusPill)
          .shadow(ShadowStyle.sm)
          .enabled(!this.isLoading)
          .margin({ top: 14 })
          .onClick(() => {
            this.searchRooms();
          })
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(Theme.bgCard)
      .borderRadius(Theme.cardRadius)
      .shadow(ShadowStyle.nmRaisedLg)
      .margin({ left: 16, right: 16, top: 12 })

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor(Theme.danger)
          .width('100%')
          .padding({ left: 16, right: 16, top: 10 })
      }

      Row() {
        Column() {
          Text(this.hasSearched ? `共 ${this.rooms.length} 间空教室` : '请选择条件后查询')
            .fontSize(Theme.fsBody)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.textPrimary)
          Text(`${this.selectedDayText()} · ${this.sectionRangeText()}`)
            .fontSize(Theme.fsCaption)
            .fontColor(Theme.textTertiary)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text(this.selectedBuildingText())
          .fontSize(Theme.fsCaption)
          .fontColor(Theme.textSecondary)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(Theme.bgInput)
          .borderRadius(Theme.chipRadius)
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 16, bottom: 10 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading && this.rooms.length === 0) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(Theme.primary)
          Text('正在查询空教室')
            .fontSize(14)
            .fontColor(Theme.textTertiary)
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.rooms.length === 0) {
        Column() {
          Text(this.hasSearched ? '当前条件下没有空教室' : '请选择条件后查询')
            .fontSize(16)
            .fontColor(Theme.textSecondary)
          Text(this.hasSearched ? '可以换一个教学楼、周次或节次再试' : '教学楼和周次可以不选')
            .fontSize(13)
            .fontColor(Theme.textTertiary)
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.rooms, (room: EmptyRoom) => {
            ListItem() {
              this.RoomCard(room)
            }
          }, (room: EmptyRoom) => `${room.id}-${room.building}-${room.roomNo}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 18 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  FilterItem(label: string, type: number) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(Theme.textTertiary)
        .width('100%')
      Row() {
        Text(this.filterValueText(type))
          .fontSize(14)
          .fontColor(Theme.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('>')
          .fontSize(13)
          .fontColor(Theme.textDisabled)
          .margin({ left: 6 })
      }
      .width('100%')
      .margin({ top: 5 })
    }
    .layoutWeight(1)
    .height(56)
    .padding({ left: 12, right: 12, top: 8, bottom: 7 })
    .backgroundColor(Theme.bgInput)
    .borderRadius(18)
    .onClick(() => {
      if (type === 1) {
        this.showBuildingPicker();
      }
      if (type === 2) {
        this.showDayPicker();
      }
      if (type === 3) {
        this.showStartSectionPicker();
      }
      if (type === 4) {
        this.showEndSectionPicker();
      }
      if (type === 5) {
        this.showWeekPicker();
      }
    })
  }

  @Builder
  RoomCard(room: EmptyRoom) {
    Column() {
      Row() {
        Column() {
          Text(this.roomTitle(room))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textPrimary)
          Text(room.type.length > 0 ? room.type : '普通教室')
            .fontSize(Theme.fsCaption)
            .fontColor(Theme.textSecondary)
            .margin({ top: 5 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('看课表')
          .fontSize(Theme.fsCaption)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.primary)
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(Theme.primaryLight)
          .borderRadius(Theme.radiusPill)
      }
      .width('100%')

      Row({ space: 8 }) {
        this.Tag(`容量 ${room.capacity}`)
        this.Tag(this.projectorText(room))
        this.Tag(this.acText(room))
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 15, bottom: 15 })
    .backgroundColor(Theme.bgCard)
    .borderRadius(20)
    .shadow(ShadowStyle.nmRaised)
    .onClick(() => {
      this.goSchedule(room);
    })
  }

  @Builder
  Tag(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor(Theme.textSecondary)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(Theme.bgInput)
      .borderRadius(Theme.chipRadius)
  }
}
