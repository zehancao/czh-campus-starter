<template>
  <div>
    <n-card title="求助记录">
      <template #header-extra>
        <n-space>
          <n-select v-model:value="filterStatus" :options="statusOptions" placeholder="全部状态" clearable style="width: 120px" @update:value="fetchReports" />
        </n-space>
      </template>
      <n-empty v-if="reports.length === 0" description="暂无求助记录" />
      <n-data-table v-else :columns="columns" :data="reports" :bordered="false" />
    </n-card>

    <n-modal v-model:show="showHandleModal" title="处理求助" preset="dialog" positive-text="确认" negative-text="取消" @positive-click="confirmHandle">
      <n-form>
        <n-form-item label="处理状态">
          <n-select v-model:value="handleStatus" :options="handleStatusOptions" />
        </n-form-item>
        <n-form-item label="处理备注">
          <n-input v-model:value="handleRemark" type="textarea" placeholder="请输入处理备注" />
        </n-form-item>
      </n-form>
    </n-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, h } from 'vue'
import { NCard, NDataTable, NEmpty, NButton, NSpace, NTag, NSelect, NModal, NForm, NFormItem, NInput, useMessage } from 'naive-ui'
import { useUserStore } from '../../stores/user'

const message = useMessage()
const userStore = useUserStore()
const reports = ref<any[]>([])
const filterStatus = ref<number | null>(null)

const showHandleModal = ref(false)
const handleId = ref<number>(0)
const handleStatus = ref<number>(1)
const handleRemark = ref('')

const statusOptions = [
  { label: '待处理', value: 0 },
  { label: '处理中', value: 1 },
  { label: '已解决', value: 2 },
]

const handleStatusOptions = [
  { label: '处理中', value: 1 },
  { label: '已解决', value: 2 },
]

const typeMap: Record<string, string> = {
  emergency: '紧急求助',
  safety: '安全隐患',
  medical: '医疗急救',
  other: '其他',
  '紧急求助': '紧急求助',
  '安全隐患': '安全隐患',
  '医疗急救': '医疗急救',
  '其他': '其他',
}

async function fetchReports() {
  const params = new URLSearchParams()
  if (filterStatus.value !== null) params.set('status', String(filterStatus.value))
  const res = await fetch(`/api/safety/list?${params.toString()}`, {
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  reports.value = json.data || []
}

function openHandle(row: any) {
  handleId.value = row.id
  handleStatus.value = 1
  handleRemark.value = ''
  showHandleModal.value = true
}

async function confirmHandle() {
  const params = new URLSearchParams()
  params.set('id', String(handleId.value))
  params.set('status', String(handleStatus.value))
  if (handleRemark.value) params.set('remark', handleRemark.value)
  const res = await fetch(`/api/safety/handle?${params.toString()}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  if (json.code === 200) {
    message.success('处理成功')
    fetchReports()
  } else {
    message.error(json.msg || '操作失败')
  }
}

const statusTag = (status: number) => {
  const map: Record<number, { type: 'warning' | 'info' | 'success'; text: string }> = {
    0: { type: 'warning', text: '待处理' },
    1: { type: 'info', text: '处理中' },
    2: { type: 'success', text: '已解决' },
  }
  const s = map[status] || { type: 'warning' as const, text: '未知' }
  return h(NTag, { type: s.type }, { default: () => s.text })
}

const columns = [
  { title: 'ID', key: 'id', width: 60 },
  { title: '求助人', key: 'reporterName', width: 80 },
  { title: '类型', key: 'type', width: 90, render: (row: any) => typeMap[row.type] || row.type },
  { title: '位置', key: 'location', width: 180, ellipsis: { tooltip: true } },
  { title: '描述', key: 'description', ellipsis: { tooltip: true } },
  { title: '时间', key: 'createTime', width: 140 },
  { title: '状态', key: 'status', width: 80, render: (row: any) => statusTag(row.status) },
  { title: '处理人', key: 'handlerName', width: 80 },
  { title: '处理备注', key: 'handleRemark', width: 120, ellipsis: { tooltip: true } },
  {
    title: '操作',
    key: 'actions',
    width: 80,
    render: (row: any) =>
      row.status === 0
        ? h(NButton, { type: 'primary', size: 'small', onClick: () => openHandle(row) }, { default: () => '处理' })
        : h('span', { style: 'color: #999' }, '已处理'),
  },
]

onMounted(() => {
  fetchReports()
})
</script>
