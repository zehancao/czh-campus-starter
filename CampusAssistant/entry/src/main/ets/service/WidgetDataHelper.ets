import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { formProvider, formBindingData } from '@kit.FormKit';
import { CourseSchedule } from '../model/Models';

const PREF_NAME: string = 'campus_widget_data';
const FORM_IDS_KEY: string = 'widget_form_ids';

interface WidgetCourseItem {
  courseName: string;
  classroom: string;
  startSection: number;
  endSection: number;
  dayOfWeek: number;
}

export class WidgetDataHelper {
  static saveFormId(context: Context, formId: string): void {
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const idsStr: string = pref.getSync(FORM_IDS_KEY, '') as string;
      let ids: string[] = [];
      if (idsStr.length > 0) {
        ids = JSON.parse(idsStr) as string[];
      }
      if (ids.indexOf(formId) < 0) {
        ids.push(formId);
        pref.putSync(FORM_IDS_KEY, JSON.stringify(ids));
        pref.flush();
      }
    } catch (e) {
    }
  }

  static removeFormId(context: Context, formId: string): void {
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const idsStr: string = pref.getSync(FORM_IDS_KEY, '') as string;
      let ids: string[] = [];
      if (idsStr.length > 0) {
        ids = JSON.parse(idsStr) as string[];
      }
      const idx: number = ids.indexOf(formId);
      if (idx >= 0) {
        ids.splice(idx, 1);
        pref.putSync(FORM_IDS_KEY, JSON.stringify(ids));
        pref.flush();
      }
    } catch (e) {
    }
  }

  static saveTodayCourses(context: Context, todayCourses: CourseSchedule[], currentWeek: number): void {
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME });
      pref.putSync('currentWeek', `${currentWeek}`);
      const items: WidgetCourseItem[] = [];
      for (let i = 0; i < todayCourses.length; i++) {
        const c: CourseSchedule = todayCourses[i];
        const item: WidgetCourseItem = {
          courseName: c.courseName,
          classroom: c.classroom,
          startSection: c.startSection,
          endSection: c.endSection,
          dayOfWeek: c.dayOfWeek,
        };
        items.push(item);
      }
      pref.putSync('todayCourses', JSON.stringify(items));
      pref.flush();
      WidgetDataHelper.notifyWidgetUpdate(context);
    } catch (e) {
    }
  }

  static notifyWidgetUpdate(context: Context): void {
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const idsStr: string = pref.getSync(FORM_IDS_KEY, '') as string;
      if (idsStr.length === 0) {
        return;
      }
      const ids: string[] = JSON.parse(idsStr) as string[];
      const formData: Record<string, Object> = WidgetDataHelper.buildFormData(context);
      const bindingData: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
      for (let i = 0; i < ids.length; i++) {
        formProvider.updateForm(ids[i], bindingData).catch(() => {
        });
      }
    } catch (e) {
    }
  }

  private static buildFormData(context: Context): Record<string, Object> {
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
      const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const weekStr: string = pref.getSync('currentWeek', '') as string;
      if (weekStr.length > 0) {
        semesterWeek = `第${weekStr}周`;
      }
      const courseJson: string = pref.getSync('todayCourses', '') as string;
      if (courseJson.length > 0) {
        courses = JSON.parse(courseJson) as WidgetCourseItem[];
      }
    } catch (e) {
    }

    if (courses.length > 0) {
      const sectionLabels: string[] = ['08:00', '08:55', '10:00', '10:55', '14:00', '14:55', '16:00', '16:55', '19:00', '19:55'];
      const nowMinutes: number = new Date().getHours() * 60 + new Date().getMinutes();
      let found: boolean = false;
      for (let i = 0; i < courses.length; i++) {
        const startIdx: number = courses[i].startSection - 1;
        const startMinutes: number = WidgetDataHelper.timeStrToMinutes(sectionLabels[startIdx]);
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

  private static timeStrToMinutes(timeStr: string): number {
    const parts: string[] = timeStr.split(':');
    if (parts.length < 2) {
      return 0;
    }
    return parseInt(parts[0]) * 60 + parseInt(parts[1]);
  }
}
