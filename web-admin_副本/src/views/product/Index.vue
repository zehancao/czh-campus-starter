<template>
  <div>
    <n-card title="待审核商品">
      <n-empty v-if="products.length === 0" description="暂无待审核商品" />
      <n-data-table v-else :columns="columns" :data="products" :bordered="false" />
    </n-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, h } from 'vue'
import { NCard, NDataTable, NEmpty, NButton, NSpace, useMessage } from 'naive-ui'
import { useUserStore } from '../../stores/user'

const message = useMessage()
const userStore = useUserStore()
const products = ref<any[]>([])

async function fetchPending() {
  const res = await fetch('/api/admin/product/pending', {
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  products.value = json.data || []
}

async function approve(id: number) {
  const res = await fetch(`/api/admin/product/approve?productId=${id}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  if (json.code === 200) {
    message.success('已通过')
    fetchPending()
  } else {
    message.error(json.msg || '操作失败')
  }
}

async function reject(id: number) {
  const res = await fetch(`/api/admin/product/reject?productId=${id}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  if (json.code === 200) {
    message.success('已拒绝')
    fetchPending()
  } else {
    message.error(json.msg || '操作失败')
  }
}

const columns = [
  { title: 'ID', key: 'id', width: 60 },
  { title: '标题', key: 'title', ellipsis: { tooltip: true } },
  { title: '价格', key: 'price', width: 80 },
  { title: '发布人', key: 'sellerName', width: 80 },
  { title: '描述', key: 'description', ellipsis: { tooltip: true } },
  {
    title: '操作',
    key: 'actions',
    width: 160,
    render: (row: any) =>
      h(NSpace, null, {
        default: () => [
          h(NButton, { type: 'success', size: 'small', onClick: () => approve(row.id) }, { default: () => '通过' }),
          h(NButton, { type: 'error', size: 'small', onClick: () => reject(row.id) }, { default: () => '拒绝' }),
        ],
      }),
  },
]

onMounted(() => {
  fetchPending()
})
</script>
