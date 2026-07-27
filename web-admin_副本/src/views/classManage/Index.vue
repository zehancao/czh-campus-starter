<template>
  <n-card title="班级管理">
    <n-space vertical :size="16">
      <n-space>
        <n-button type="primary" @click="openGradeModal">编辑年级</n-button>
      </n-space>

      <n-form inline>
        <n-form-item label="年级">
          <n-select v-model:value="grade" :options="gradeOptions" placeholder="全部" clearable style="width: 100px" @update:value="onGradeChange" />
        </n-form-item>
        <n-form-item label="学院">
          <n-select v-model:value="collegeId" :options="collegeOptions" placeholder="全部" clearable style="width: 180px" @update:value="onCollegeChange" />
        </n-form-item>
        <n-form-item label="专业">
          <n-select v-model:value="majorId" :options="majorOptions" placeholder="全部" clearable style="width: 180px" @update:value="onMajorChange" />
        </n-form-item>
      </n-form>

      <n-table :bordered="true" :single-line="false" size="small">
        <thead>
          <tr>
            <th>年级</th>
            <th>学院</th>
            <th>专业</th>
            <th>班级名称</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in classes" :key="item.id">
            <td>{{ item.grade }}</td>
            <td>{{ item.college }}</td>
            <td>{{ item.major }}</td>
            <td>{{ item.name }}</td>
            <td>
              <n-popconfirm @positive-click="handleDelete(item.id)">
                <template #trigger>
                  <n-button text type="error" size="small">删除</n-button>
                </template>
                确定删除班级「{{ item.name }}」吗？
              </n-popconfirm>
            </td>
          </tr>
        </tbody>
      </n-table>
      <n-empty v-if="!classes.length" description="暂无班级数据" />
    </n-space>

    <n-modal v-model:show="showGradeModal" title="编辑年级" preset="card" style="width: 560px">
      <n-tabs type="line">
        <n-tab-pane name="add" tab="添加年级">
          <n-form label-placement="top" style="margin-top: 16px">
            <n-form-item label="新年级">
              <n-input v-model:value="addGrade" placeholder="如：2025" style="width: 200px" />
            </n-form-item>
            <n-alert v-if="addGradePreview.length" type="info" style="margin-top: 8px">
              将创建 {{ addGradePreview.length }} 个班级：<br />
              <span v-for="(p, i) in addGradePreview.slice(0, 10)" :key="i">{{ p }}；</span>
              <span v-if="addGradePreview.length > 10">...等共 {{ addGradePreview.length }} 个</span>
            </n-alert>
            <n-space style="margin-top: 16px">
              <n-button @click="showGradeModal = false">取消</n-button>
              <n-button type="primary" :loading="submitting" :disabled="!addGrade" @click="handleAddGrade">确定添加</n-button>
            </n-space>
          </n-form>
        </n-tab-pane>
        <n-tab-pane name="delete" tab="删除年级">
          <n-form label-placement="top" style="margin-top: 16px">
            <n-form-item label="选择要删除的年级">
              <n-checkbox-group v-model:value="deleteGrades">
                <n-space item-style="display: flex;">
                  <n-checkbox v-for="g in gradeList" :key="g" :value="g" :label="g + '级'" />
                </n-space>
              </n-checkbox-group>
            </n-form-item>
            <n-alert v-if="deleteGrades.length" type="warning" style="margin-top: 8px">
              将删除 {{ deleteGrades.length }} 个年级下的所有班级数据，此操作不可撤销！
            </n-alert>
            <n-space style="margin-top: 16px">
              <n-button @click="showGradeModal = false">取消</n-button>
              <n-popconfirm @positive-click="handleDeleteGrades">
                <template #trigger>
                  <n-button type="error" :loading="submitting" :disabled="!deleteGrades.length">确定删除</n-button>
                </template>
                确定删除所选年级的所有班级吗？此操作不可撤销。
              </n-popconfirm>
            </n-space>
          </n-form>
        </n-tab-pane>
      </n-tabs>
    </n-modal>
  </n-card>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { NCard, NSpace, NButton, NForm, NFormItem, NSelect, NInput, NTable, NEmpty, NModal, NPopconfirm, NAlert, NTabs, NTabPane, NCheckboxGroup, NCheckbox, useMessage } from 'naive-ui'
import { getClasses, getColleges, getMajors, getGrades, batchAddClass, deleteClassByGrade, deleteClass } from '../../api/admin'

const message = useMessage()
const classes = ref<any[]>([])
const showGradeModal = ref(false)
const submitting = ref(false)

const grade = ref<string | null>(null)
const collegeId = ref<number | null>(null)
const majorId = ref<number | null>(null)

const gradeList = ref<string[]>([])
const gradeOptions = ref<{ label: string; value: string }[]>([])
const collegeOptions = ref<{ label: string; value: number }[]>([])
const majorOptions = ref<{ label: string; value: number }[]>([])

const collegeMap = ref<Record<number, string>>({})
const majorMap = ref<Record<number, string>>({})
const collegeMajorMap = ref<Record<number, number[]>>({})

const prefixMap: Record<string, string> = {
  '物联网工程': '物联网', '计算机科学与技术': '计算机', '软件工程': '软工',
  '数据科学与大数据技术': '大数据', '人工智能': '智能', '网络安全与执法': '网安',
  '飞行技术': '飞行', '飞行器设计与工程': '飞设', '飞行器动力工程': '飞动',
  '航空航天工程': '空天', '交通运输': '交运', '交通管理': '交管',
  '物流管理': '物流', '工商管理': '工商', '市场营销': '营销',
  '信息与计算科学': '信科', '应用物理学': '应物', '安全工程': '安全', '消防工程': '消防',
}

const addGrade = ref('')
const deleteGrades = ref<string[]>([])

const addGradePreview = computed(() => {
  if (!addGrade.value || addGrade.value.length !== 4) return []
  const shortYear = addGrade.value.substring(2)
  const result: string[] = []
  for (const [mid, mname] of Object.entries(majorMap.value)) {
    const prefix = prefixMap[mname] || mname.substring(0, 2)
    result.push(`${prefix}${shortYear}01`)
    result.push(`${prefix}${shortYear}02`)
  }
  return result
})

onMounted(async () => {
  try {
    const [gradeRes, collegeRes, allMajorsRes]: any[] = await Promise.all([getGrades(), getColleges(), getMajors()])
    gradeList.value = gradeRes.data
    gradeOptions.value = gradeRes.data.map((g: string) => ({ label: g, value: g }))
    collegeOptions.value = collegeRes.data.map((c: any) => ({ label: c.name, value: c.id }))
    const cmap: Record<number, string> = {}
    collegeRes.data.forEach((c: any) => { cmap[c.id] = c.name })
    collegeMap.value = cmap
    const mmap: Record<number, string> = {}
    allMajorsRes.data.forEach((m: any) => { mmap[m.id] = m.name })
    majorMap.value = mmap
    collegeRes.data.forEach((c: any) => {
      collegeMajorMap.value[c.id] = allMajorsRes.data.filter((m: any) => m.collegeId === c.id).map((m: any) => m.id)
    })
    loadClasses()
  } catch (e: any) {
    message.error('加载基础数据失败')
  }
})

async function onGradeChange() {
  majorId.value = null
  await loadMajorsAndClasses()
}

async function onCollegeChange() {
  majorId.value = null
  await loadMajorsAndClasses()
}

async function onMajorChange() {
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
    classes.value = res.data || []
  } catch {
    classes.value = []
  }
}

async function reloadGrades() {
  const res: any = await getGrades()
  gradeList.value = res.data
  gradeOptions.value = res.data.map((g: string) => ({ label: g, value: g }))
}

function openGradeModal() {
  addGrade.value = ''
  deleteGrades.value = []
  showGradeModal.value = true
}

async function handleAddGrade() {
  if (!addGrade.value || addGrade.value.length !== 4) {
    message.warning('请输入4位年份，如2025')
    return
  }
  submitting.value = true
  try {
    const allMajorIds = Object.keys(majorMap.value).map(Number)
    const res: any = await batchAddClass({
      grade: addGrade.value,
      collegeIds: [],
      majorIds: allMajorIds,
      classCount: 2,
    })
    message.success(`已创建 ${res.data} 个班级（${addGrade.value}级）`)
    addGrade.value = ''
    await reloadGrades()
    await loadClasses()
  } catch (e: any) {
    message.error(e.message || '添加失败')
  } finally {
    submitting.value = false
  }
}

async function handleDeleteGrades() {
  submitting.value = true
  try {
    let total = 0
    for (const g of deleteGrades.value) {
      const res: any = await deleteClassByGrade(g)
      total += res.data
    }
    message.success(`已删除 ${deleteGrades.value.length} 个年级，共 ${total} 个班级`)
    deleteGrades.value = []
    await reloadGrades()
    await loadClasses()
  } catch (e: any) {
    message.error(e.message || '删除失败')
  } finally {
    submitting.value = false
  }
}

async function handleDelete(id: number) {
  try {
    await deleteClass(id)
    message.success('删除成功')
    loadClasses()
  } catch (e: any) {
    message.error('删除失败')
  }
}
</script>
