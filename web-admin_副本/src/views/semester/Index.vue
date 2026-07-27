<template>
  <n-card title="学期管理">
    <n-space vertical :size="16">
      <n-button type="primary" @click="openModal('add'); resetForm()">新增学期</n-button>

      <n-table :bordered="true" :single-line="false" size="small">
        <thead>
          <tr>
            <th>学期名称</th>
            <th>开始日期</th>
            <th>结束日期</th>
            <th>总周数</th>
            <th>当前学期</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in semesters" :key="item.id">
            <td>{{ item.name }}</td>
            <td>{{ item.startDate }}</td>
            <td>{{ item.endDate }}</td>
            <td>{{ item.weekCount }}</td>
            <td>
              <n-tag v-if="item.isCurrent" type="success" size="small">当前学期</n-tag>
              <n-button v-else text type="primary" size="small" @click="handleSetCurrent(item.id)">设为当前</n-button>
            </td>
            <td>
              <n-space :size="8">
                <n-button text type="info" size="small" @click="openModal('edit', item)">编辑</n-button>
                <n-popconfirm @positive-click="handleDelete(item.id)">
                  <template #trigger>
                    <n-button text type="error" size="small">删除</n-button>
                  </template>
                  确定删除该学期吗？删除后关联课表数据将丢失。
                </n-popconfirm>
              </n-space>
            </td>
          </tr>
        </tbody>
      </n-table>

      <n-empty v-if="!semesters.length" description="暂无学期数据" />
    </n-space>

    <n-modal v-model:show="showModal" :title="modalMode === 'add' ? '新增学期' : '编辑学期'" preset="card" style="width: 500px">
      <n-form :model="form" label-placement="top">
        <n-form-item label="学期名称">
          <n-input v-model:value="form.name" placeholder="如：2025-2026学年第二学期" />
        </n-form-item>
        <n-form-item label="开始日期">
          <n-date-picker v-model:value="form.startDateTs" type="date" style="width: 100%" />
        </n-form-item>
        <n-form-item label="结束日期">
          <n-date-picker v-model:value="form.endDateTs" type="date" style="width: 100%" />
        </n-form-item>
        <n-form-item label="总周数">
          <n-input-number v-model:value="form.weekCount" :min="1" :max="30" />
        </n-form-item>
        <n-form-item label="设为当前学期">
          <n-switch v-model:value="form.isCurrentBool" />
        </n-form-item>
      </n-form>
      <template #action>
        <n-space>
          <n-button @click="showModal = false">取消</n-button>
          <n-button type="primary" :loading="submitting" @click="handleSubmit">确定</n-button>
        </n-space>
      </template>
    </n-modal>
  </n-card>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { NCard, NSpace, NButton, NTable, NTag, NEmpty, NModal, NForm, NFormItem, NInput, NDatePicker, NInputNumber, NSwitch, NPopconfirm, useMessage } from 'naive-ui'
import { getSemesters, addSemester, updateSemester, setCurrentSemester, deleteSemester } from '../../api/admin'

const message = useMessage()
const semesters = ref<any[]>([])
const showModal = ref(false)
const submitting = ref(false)
const modalMode = ref<'add' | 'edit'>('add')
const editingId = ref<number>(0)

const form = reactive({
  name: '',
  startDateTs: null as number | null,
  endDateTs: null as number | null,
  weekCount: 16,
  isCurrentBool: false,
})

function resetForm() {
  form.name = ''
  form.startDateTs = null
  form.endDateTs = null
  form.weekCount = 16
  form.isCurrentBool = false
}

function dateToTs(dateStr: string): number | null {
  if (!dateStr) return null
  return new Date(dateStr).getTime()
}

function tsToDate(ts: number | null): string {
  if (!ts) return ''
  const d = new Date(ts)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function openModal(mode: 'add' | 'edit', item?: any) {
  modalMode.value = mode
  if (mode === 'edit' && item) {
    editingId.value = item.id
    form.name = item.name
    form.startDateTs = dateToTs(item.startDate)
    form.endDateTs = dateToTs(item.endDate)
    form.weekCount = item.weekCount
    form.isCurrentBool = !!item.isCurrent
  } else {
    resetForm()
  }
  showModal.value = true
}

onMounted(loadData)

async function loadData() {
  try {
    const res: any = await getSemesters()
    semesters.value = res.data || []
  } catch (e: any) {
    message.error('加载学期数据失败')
  }
}

async function handleSubmit() {
  if (!form.name || !form.startDateTs || !form.endDateTs) {
    message.warning('请填写完整信息')
    return
  }
  submitting.value = true
  try {
    const payload = {
      name: form.name,
      startDate: tsToDate(form.startDateTs),
      endDate: tsToDate(form.endDateTs),
      weekCount: form.weekCount,
      isCurrent: form.isCurrentBool ? 1 : 0,
    }
    if (modalMode.value === 'add') {
      await addSemester(payload)
      message.success('添加成功')
    } else {
      await updateSemester(editingId.value, payload)
      message.success('编辑成功')
    }
    showModal.value = false
    loadData()
  } catch (e: any) {
    message.error(e.message || '操作失败')
  } finally {
    submitting.value = false
  }
}

async function handleSetCurrent(id: number) {
  try {
    await setCurrentSemester(id)
    message.success('已设为当前学期')
    loadData()
  } catch (e: any) {
    message.error('操作失败')
  }
}

async function handleDelete(id: number) {
  try {
    await deleteSemester(id)
    message.success('删除成功')
    loadData()
  } catch (e: any) {
    message.error('删除失败')
  }
}
</script>
