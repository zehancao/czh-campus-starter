import { ApiService, ApiResult } from '../service/ApiService';
import { PickerOption } from '../model/Models';
import { Constants } from '../common/Constants';

@Component
struct SelectField {
  @Prop label: string = '';
  @Prop value: string = '';
  onTap: () => void = () => {};

  build() {
    Row() {
      Text(this.value.length > 0 ? this.value : `请选择${this.label}`)
        .fontSize(16)
        .fontColor(this.value.length > 0 ? '#333333' : '#CCCCCC')
      Blank()
      Text('>')
        .fontSize(14)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(48)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .padding({ left: 16, right: 16 })
    .margin({ top: 12 })
    .onClick(() => {
      this.onTap();
    })
  }
}

@Entry
@Component
struct RegisterPage {
  @State studentId: string = '';
  @State name: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State phone: string = '';
  @State hometown: string = '';
  @State errorMsg: string = '';
  @State isLoading: boolean = false;

  @State grade: string = '';
  @State collegeId: number = 0;
  @State collegeName: string = '';
  @State majorId: number = 0;
  @State majorName: string = '';
  @State classId: number = 0;
  @State className: string = '';
  @State classNames: PickerOption[] = [];

  @State province: string = '';

  @State grades: string[] = [];
  @State colleges: PickerOption[] = [];
  @State majors: PickerOption[] = [];

  aboutToAppear(): void {
    this.loadGrades();
    this.loadColleges();
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor('#333333')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('注册账号')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          TextInput({ placeholder: '请输入学号', text: this.studentId })
            .type(InputType.Number)
            .height(48)
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.studentId = value;
              this.errorMsg = '';
            })

          TextInput({ placeholder: '请输入姓名', text: this.name })
            .height(48)
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.name = value;
              this.errorMsg = '';
            })

          TextInput({ placeholder: '请输入密码', text: this.password })
            .type(InputType.Password)
            .height(48)
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.password = value;
              this.errorMsg = '';
            })

          TextInput({ placeholder: '请确认密码', text: this.confirmPassword })
            .type(InputType.Password)
            .height(48)
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.confirmPassword = value;
              this.errorMsg = '';
            })

          TextInput({ placeholder: '请输入手机号', text: this.phone })
            .type(InputType.PhoneNumber)
            .height(48)
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.phone = value;
              this.errorMsg = '';
            })

          SelectField({ label: '年级', value: this.grade, onTap: () => { this.showGradePicker(); } })
          SelectField({ label: '学院', value: this.collegeName, onTap: () => { this.showCollegePicker(); } })
          SelectField({ label: '专业', value: this.majorName, onTap: () => { this.showMajorPicker(); } })
          SelectField({ label: '班级', value: this.className, onTap: () => { this.showClassPicker(); } })
          SelectField({ label: '籍贯', value: this.province, onTap: () => { this.showProvincePicker(); } })

          if (this.errorMsg.length > 0) {
            Text(this.errorMsg)
              .fontSize(12)
              .fontColor('#FF4444')
              .margin({ top: 12 })
          }

          Button('注 册')
            .width('100%')
            .height(48)
            .fontSize(18)
            .fontColor(Color.White)
            .backgroundColor('#4A90D9')
            .borderRadius(24)
            .enabled(!this.isLoading)
            .margin({ top: 24, bottom: 24 })
            .onClick(() => {
              this.handleRegister();
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  private async loadGrades(): Promise<void> {
    const result: ApiResult = await ApiService.getPublicGrades();
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const list: string[] = [];
      for (let i = 0; i < arr.length; i++) {
        list.push(arr[i] as string);
      }
      this.grades = list;
    }
  }

  private async loadColleges(): Promise<void> {
    const result: ApiResult = await ApiService.getPublicColleges();
    if (result.code === 200 && result.data !== undefined) {
      this.colleges = ApiService.parsePickerOptions(result.data);
    }
  }

  private async loadMajors(collegeId: number): Promise<void> {
    const result: ApiResult = await ApiService.getPublicMajors(collegeId);
    if (result.code === 200 && result.data !== undefined) {
      this.majors = ApiService.parsePickerOptions(result.data);
    } else {
      this.majors = [];
    }
  }

  private async loadClasses(grade: string, collegeId: number, majorId: number): Promise<void> {
    if (grade.length === 0 || collegeId === 0 || majorId === 0) {
      this.classNames = [];
      return;
    }
    const result: ApiResult = await ApiService.getPublicClasses(grade, collegeId, majorId);
    if (result.code === 200 && result.data !== undefined) {
      this.classNames = ApiService.parsePickerOptions(result.data);
    } else {
      this.classNames = [];
    }
  }

  private showProvincePicker(): void {
    const provinces: string[] = Constants.HOMETOWN_OPTIONS;
    let currentIdx: number = Math.max(provinces.indexOf(this.province), 0);
    TextPickerDialog.show({
      range: provinces,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        currentIdx = value.index as number;
        if (currentIdx >= 0 && currentIdx < provinces.length) {
          this.province = provinces[currentIdx];
          this.hometown = this.province;
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < provinces.length) {
          this.province = provinces[idx];
        }
        this.hometown = this.province;
      }
    });
  }

  private showGradePicker(): void {
    if (this.grades.length === 0) {
      this.errorMsg = '年级数据加载中，请稍候';
      return;
    }
    let currentIdx: number = Math.max(this.grades.indexOf(this.grade), 0);
    TextPickerDialog.show({
      range: this.grades,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        currentIdx = value.index as number;
        this.grade = this.grades[currentIdx];
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < this.grades.length) {
          this.grade = this.grades[idx];
        }
        this.classId = 0;
        this.className = '';
        this.loadClasses(this.grade, this.collegeId, this.majorId);
      }
    });
  }

  private showCollegePicker(): void {
    if (this.colleges.length === 0) {
      this.errorMsg = '学院数据加载中，请稍候';
      return;
    }
    const names: string[] = [];
    for (let i = 0; i < this.colleges.length; i++) {
      names.push(this.colleges[i].name);
    }
    let currentIdx: number = Math.max(names.indexOf(this.collegeName), 0);
    TextPickerDialog.show({
      range: names,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        currentIdx = value.index as number;
        if (currentIdx >= 0 && currentIdx < this.colleges.length) {
          this.collegeName = this.colleges[currentIdx].name;
          this.collegeId = this.colleges[currentIdx].id;
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < this.colleges.length) {
          this.collegeName = this.colleges[idx].name;
          this.collegeId = this.colleges[idx].id;
        }
        this.majorId = 0;
        this.majorName = '';
        this.classId = 0;
        this.className = '';
        this.classNames = [];
        this.loadMajors(this.collegeId);
      }
    });
  }

  private showMajorPicker(): void {
    if (this.collegeName.length === 0) {
      this.errorMsg = '请先选择学院';
      return;
    }
    if (this.majors.length === 0) {
      this.errorMsg = '该学院暂无专业数据';
      return;
    }
    const names: string[] = [];
    for (let i = 0; i < this.majors.length; i++) {
      names.push(this.majors[i].name);
    }
    let currentIdx: number = Math.max(names.indexOf(this.majorName), 0);
    TextPickerDialog.show({
      range: names,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        currentIdx = value.index as number;
        if (currentIdx >= 0 && currentIdx < this.majors.length) {
          this.majorName = this.majors[currentIdx].name;
          this.majorId = this.majors[currentIdx].id;
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < this.majors.length) {
          this.majorName = this.majors[idx].name;
          this.majorId = this.majors[idx].id;
        }
        this.classId = 0;
        this.className = '';
        this.loadClasses(this.grade, this.collegeId, this.majorId);
      }
    });
  }

  private showClassPicker(): void {
    if (this.grade.length === 0 || this.majorName.length === 0) {
      this.errorMsg = '请先选择年级和专业';
      return;
    }
    if (this.classNames.length === 0) {
      this.errorMsg = '暂无匹配的班级数据';
      return;
    }
    const names: string[] = [];
    for (let i = 0; i < this.classNames.length; i++) {
      names.push(this.classNames[i].name);
    }
    let currentIdx: number = Math.max(names.indexOf(this.className), 0);
    TextPickerDialog.show({
      range: names,
      selected: currentIdx,
      onChange: (value: TextPickerResult) => {
        currentIdx = value.index as number;
        if (currentIdx >= 0 && currentIdx < this.classNames.length) {
          this.className = this.classNames[currentIdx].name;
          this.classId = this.classNames[currentIdx].id;
        }
      },
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < this.classNames.length) {
          this.className = this.classNames[idx].name;
          this.classId = this.classNames[idx].id;
        }
      }
    });
  }

  private async handleRegister(): Promise<void> {
    if (this.studentId.length === 0) {
      this.errorMsg = '请输入学号';
      return;
    }
    if (this.name.length === 0) {
      this.errorMsg = '请输入姓名';
      return;
    }
    if (this.password.length === 0) {
      this.errorMsg = '请输入密码';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMsg = '两次密码输入不一致';
      return;
    }
    if (this.phone.length === 0) {
      this.errorMsg = '请输入手机号';
      return;
    }
    if (this.collegeName.length === 0) {
      this.errorMsg = '请选择学院';
      return;
    }
    if (this.majorName.length === 0) {
      this.errorMsg = '请选择专业';
      return;
    }
    if (this.grade.length === 0) {
      this.errorMsg = '请选择年级';
      return;
    }
    if (this.className.length === 0) {
      this.errorMsg = '请选择班级';
      return;
    }

    this.isLoading = true;
    const params: Record<string, string> = {
      'name': this.name,
      'studentId': this.studentId,
      'phone': this.phone,
      'grade': this.grade,
      'college': this.collegeName,
      'major': this.majorName,
      'className': this.className,
      'hometown': this.hometown,
      'password': this.password
    };
    const result: ApiResult = await ApiService.register(params);
    this.isLoading = false;
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '注册成功，请登录' });
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
    } else {
      this.errorMsg = result.msg.length > 0 ? result.msg : '注册失败';
    }
  }
}
