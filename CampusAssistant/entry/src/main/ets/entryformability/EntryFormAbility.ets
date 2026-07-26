import { FormExtensionAbility, formBindingData, formProvider, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { WidgetDataHelper } from '../service/WidgetDataHelper';

const DOMAIN: number = 0x0000;
const TAG: string = 'EntryFormAbility';
const PREF_NAME: string = 'campus_widget_data';

interface WidgetCourseItem {
  courseName: string;
  classroom: string;
  startSection: number;
  endSection: number;
  dayOfWeek: number;
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN, TAG, 'onAddForm');
    const formId: string = (want.parameters !== undefined ? want.parameters[formInfo.FormParam.IDENTITY_KEY] : '') as string;
    hilog.info(DOMAIN, TAG, `formId: ${formId}`);
    WidgetDataHelper.saveFormId(this.context, formId);
    const formData: Record<string, Object> = this.buildFormData();
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN, TAG, `onUpdateForm formId: ${formId}`);
    const formData: Record<string, Object> = this.buildFormData();
    const bindingData: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, bindingData).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, `updateForm failed: ${err.message}`);
    });
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN, TAG, `onFormEvent formId: ${formId}, message: ${message}`);
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN, TAG, `onRemoveForm formId: ${formId}`);
    WidgetDataHelper.removeFormId(this.context, formId);
  }

  private buildFormData(): Record<string, Object> {
    const today: number = new Date().getDay();
    const dayOfWeek: number = today === 0 ? 7 : today;
    const weekLabels: string[] = ['一', '二', '三', '四', '五', '六', '日'];
    const month: number = new Date().getMonth() + 1;
    const date: number = new Date().getDate();
    const dateStr: string = `${month}月${date}日 周${weekLabels[dayOfWeek - 1]}`;

    let semesterWeek: string = '';
    let courses: WidgetCourseItem[] = [];
    let nextCourse: string = '';

    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: PREF_NAME });
      const weekStr: string = pref.getSync('currentWeek', '') as string;
      if (weekStr.length > 0) {
        semesterWeek = `第${weekStr}周`;
      }
      const courseJson: string = pref.getSync('todayCourses', '') as string;
      if (courseJson.length > 0) {
        courses = JSON.parse(courseJson) as WidgetCourseItem[];
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'read preferences failed');
    }

    if (courses.length > 0) {
      const sectionLabels: string[] = ['08:00', '08:55', '10:00', '10:55', '14:00', '14:55', '16:00', '16:55', '19:00', '19:55'];
      const nowMinutes: number = new Date().getHours() * 60 + new Date().getMinutes();
      let found: boolean = false;
      for (let i = 0; i < courses.length; i++) {
        const startIdx: number = courses[i].startSection - 1;
        const startMinutes: number = this.timeStrToMinutes(sectionLabels[startIdx]);
        if (startMinutes > nowMinutes && !found) {
          nextCourse = `下节课: ${courses[i].courseName} @ ${courses[i].classroom}`;
          found = true;
        }
      }
    }

    const result: Record<string, Object> = {
      'dateStr': dateStr,
      'semesterWeek': semesterWeek,
      'courseCount': courses.length,
      'nextCourse': nextCourse,
    };

    for (let i = 0; i < 5; i++) {
      if (i < courses.length) {
        const sectionLabels: string[] = ['08:00', '08:55', '10:00', '10:55', '14:00', '14:55', '16:00', '16:55', '19:00', '19:55'];
        const startIdx: number = courses[i].startSection - 1;
        const endIdx: number = courses[i].endSection - 1;
        result[`c${i}_name`] = courses[i].courseName;
        result[`c${i}_room`] = courses[i].classroom;
        result[`c${i}_time`] = `${sectionLabels[startIdx]}-${sectionLabels[endIdx]}`;
      } else {
        result[`c${i}_name`] = '';
        result[`c${i}_room`] = '';
        result[`c${i}_time`] = '';
      }
    }

    return result;
  }

  private timeStrToMinutes(timeStr: string): number {
    const parts: string[] = timeStr.split(':');
    if (parts.length < 2) {
      return 0;
    }
    return parseInt(parts[0]) * 60 + parseInt(parts[1]);
  }
}
