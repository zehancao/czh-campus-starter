<template>
  <n-card title="课表导入">
    <n-space vertical :size="16">
      <n-form inline>
        <n-form-item label="学期">
          <n-select v-model:value="semesterId" :options="semesterOptions" placeholder="选择学期" style="width: 250px" />
        </n-form-item>
        <n-form-item label="年级">
          <n-select v-model:value="grade" :options="gradeOptions" placeholder="全部" clearable style="width: 100px" @update:value="onGradeChange" />
        </n-form-item>
        <n-form-item label="学院">
          <n-select v-model:value="collegeId" :options="collegeOptions" placeholder="全部" clearable style="width: 180px" @update:value="onCollegeChange" />
        </n-form-item>
        <n-form-item label="专业">
          <n-select v-model:value="majorId" :options="majorOptions" placeholder="全部" clearable style="width: 180px" @update:value="onMajorChange" />
        </n-form-item>
        <n-form-item label="班级">
          <n-select v-model:value="classId" :options="classOptions" placeholder="选择班级" style="width: 160px" />
        </n-form-item>
      </n-form>

      <n-space>
        <n-button type="primary" @click="loadExisting" :disabled="!semesterId || !classId">查看已有课表</n-button>
        <n-upload :max="1" accept=".xlsx,.xls" :default-upload="false" @change="handleFileChange" :file-list="fileList">
          <n-button>选择Excel文件</n-button>
        </n-upload>
        <n-button type="primary" :loading="importing" :disabled="!file || !semesterId || !classId" @click="handleImport">
          导入课表
        </n-button>
      </n-space>

      <n-alert v-if="importResult.length" type="success" :title="`成功导入 ${importResult.length} 条课程记录`" />

      <div v-if="timetable.length" style="margin-top: 16px">
        <h3 style="margin-bottom: 12px">{{ currentClassName }} - 课表预览</h3>
        <n-table :bordered="true" :single-line="false" size="small">
          <thead>
            <tr>
              <th>星期</th>
              <th>节次</th>
              <th>课程</th>
              <th>教师</th>
              <th>教室</th>
              <th>周次</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in timetable" :key="item.id">
              <td>{{ dayNames[item.dayOfWeek] }}</td>
              <td>{{ item.startSection }}-{{ item.endSection }}节</td>
              <td><n-tag :color="{ color: item.color + '22', textColor: item.color, borderColor: item.color }">{{ item.courseName }}</n-tag></td>
              <td>{{ item.teacher }}</td>
              <td>{{ item.classroom }}</td>
              <td>{{ item.startWeek }}-{{ item.endWeek }}周</td>
            </tr>
          </tbody>
        </n-table>
      </div>

      <n-empty v-if="!timetable.length && loaded" description="该班级暂无课表数据" />
    </n-space>
  </n-card>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { NCard, NSpace, NForm, NFormItem, NSelect, NButton, NUpload, NAlert, NTable, NTag, NEmpty, useMessage } from 'naive-ui'
import { getSemesters, getClasses, getColleges, getMajors, getGrades, getTimetableByClass, importSchedule } from '../../api/admin'

const message = useMessage()

const semesterId = ref<number | null>(null)
const grade = ref<string | null>(null)
const collegeId = ref<number | null>(null)
const majorId = ref<number | null>(null)
const classId = ref<number | null>(null)

const semesterOptions = ref<{ label: string; value: number }[]>([])
const gradeOptions = ref<{ label: string; value: string }[]>([])
const collegeOptions = ref<{ label: string; value: number }[]>([])
const majorOptions = ref<{ label: string; value: number }[]>([])
const classOptions = ref<{ label: string; value: number }[]>([])
const timetable = ref<any[]>([])
const importResult = ref<any[]>([])
const file = ref<File | null>(null)
const fileList = ref<any[]>([])
const importing = ref(false)
const loaded = ref(false)

const dayNames: Record<number, string> = { 1: '周一', 2: '周二', 3: '周三', 4: '周四', 5: '周五', 6: '周六', 7: '周日' }

const currentClassName = computed(() => {
  const opt = classOptions.value.find(o => o.value === classId.value)
  return opt?.label || ''
})

onMounted(async () => {
  try {
    const [semRes, gradeRes, collegeRes]: any[] = await Promise.all([getSemesters(), getGrades(), getColleges()])
    semesterOptions.value = semRes.data.map((s: any) => ({ label: s.name, value: s.id }))
    gradeOptions.value = gradeRes.data.map((g: string) => ({ label: g, value: g }))
    collegeOptions.value = collegeRes.data.map((c: any) => ({ label: c.name, value: c.id }))
    if (semesterOptions.value.length) {
      const current = semRes.data.find((s: any) => s.isCurrent === 1)
      semesterId.value = current?.id || semesterOptions.value[0].value
    }
    loadClasses()
  } catch (e: any) {
    message.error('加载基础数据失败')
  }
})

async function onGradeChange() {
  majorId.value = null
  classId.value = null
  await loadMajorsAndClasses()
}

async function onCollegeChange() {
  majorId.value = null
  classId.value = null
  await loadMajorsAndClasses()
}

async function onMajorChange() {
  classId.value = null
  await loadClasses()
}

async function loadMajorsAndClasses() {
  if (collegeId.value) {
    const res: any = await getMajors(collegeId.value)
    majorOptions.value = res.data.map((m: any) => ({ label: m.name, value: m.id }))
  } else {
    majorOptions.value = []
  }
  await loadClasses()
}

async function loadClasses() {
  try {
    const res: any = await getClasses(grade.value || undefined, collegeId.value || undefined, majorId.value || undefined)
    classOptions.value = res.data.map((c: any) => ({ label: c.name, value: c.id }))
  } catch {
    classOptions.value = []
  }
}

async function loadExisting() {
  if (!semesterId.value || !classId.value) return
  loaded.value = true
  try {
    const res: any = await getTimetableByClass(classId.value, semesterId.value)
    timetable.value = res.data || []
  } catch {
    timetable.value = []
  }
}

function handleFileChange(data: { file: any; fileList: any[] }) {
  if (data.file?.file) {
    file.value = data.file.file
  }
  fileList.value = data.fileList
}

async function handleImport() {
  if (!file.value || !semesterId.value || !classId.value) return
  importing.value = true
  try {
    const res: any = await importSchedule(file.value, classId.value, semesterId.value)
    importResult.value = res.data || []
    timetable.value = res.data || []
    message.success(`成功导入 ${importResult.value.length} 条课表记录`)
    fileList.value = []
    file.value = null
  } catch (e: any) {
    message.error(e.message || '导入失败')
  } finally {
    importing.value = false
  }
}
</script>
