<template>
  <div>
    <n-card title="投诉记录">
      <n-empty v-if="complaints.length === 0" description="暂无投诉记录" />
      <n-data-table v-else :columns="columns" :data="complaints" :bordered="false" />
    </n-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, h } from 'vue'
import { NCard, NDataTable, NEmpty, NButton, NSpace, NTag, useMessage } from 'naive-ui'
import { useUserStore } from '../../stores/user'

const message = useMessage()
const userStore = useUserStore()
const complaints = ref<any[]>([])

async function fetchComplaints() {
  const res = await fetch('/api/complaint/list', {
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  complaints.value = json.data || []
}

async function processComplaint(id: number) {
  const res = await fetch(`/api/complaint/process/${id}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  if (json.code === 200) {
    message.success('已处理')
    fetchComplaints()
  } else {
    message.error(json.msg || '操作失败')
  }
}

const columns = [
  { title: 'ID', key: 'id', width: 60 },
  { title: '投诉人', key: 'complainantName', width: 80 },
  { title: '被投诉人', key: 'defendantName', width: 80 },
  { title: '被投诉人信用分', key: 'defendantCreditScore', width: 120, render: (row: any) => h(NTag, { type: row.defendantCreditScore >= 85 ? 'success' : 'error' }, { default: () => row.defendantCreditScore }) },
  { title: '原因', key: 'reason', ellipsis: { tooltip: true } },
  { title: '时间', key: 'createTime', width: 160 },
  {
    title: '状态',
    key: 'status',
    width: 80,
    render: (row: any) => h(NTag, { type: row.status === 0 ? 'warning' : 'success' }, { default: () => row.status === 0 ? '待处理' : '已处理' }),
  },
  {
    title: '操作',
    key: 'actions',
    width: 80,
    render: (row: any) =>
      row.status === 0
        ? h(NButton, { type: 'primary', size: 'small', onClick: () => processComplaint(row.id) }, { default: () => '处理' })
        : h('span', { style: 'color: #999' }, '已处理'),
  },
]

onMounted(() => {
  fetchComplaints()
})
</script>
