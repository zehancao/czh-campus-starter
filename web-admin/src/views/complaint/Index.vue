<template>
  <div>
    <n-card title="投诉记录">
      <n-empty v-if="complaints.length === 0" description="暂无投诉记录" />
      <n-data-table v-else :columns="columns" :data="complaints" :bordered="false" />
    </n-card>

    <n-modal
      v-model:show="showReviewModal"
      preset="card"
      title="投诉审核"
      :bordered="false"
      style="width: 760px"
    >
      <div v-if="currentComplaint">
        <n-descriptions :column="2" bordered size="small" label-placement="left">
          <n-descriptions-item label="投诉人">
            {{ currentComplaint.complainantName || '-' }}
          </n-descriptions-item>
          <n-descriptions-item label="被投诉人">
            {{ currentComplaint.defendantName || '-' }}
          </n-descriptions-item>
          <n-descriptions-item label="被投诉人信用分">
            <n-tag :type="currentComplaint.defendantCreditScore >= 85 ? 'success' : 'error'">
              {{ currentComplaint.defendantCreditScore ?? '-' }}
            </n-tag>
          </n-descriptions-item>
          <n-descriptions-item label="投诉时间">
            {{ currentComplaint.createTime || '-' }}
          </n-descriptions-item>
          <n-descriptions-item label="投诉原因" :span="2">
            {{ currentComplaint.reason || '-' }}
          </n-descriptions-item>
        </n-descriptions>

        <n-divider />

        <div class="chat-header">
          <span>双方聊天记录</span>
          <span class="chat-tip">用于管理员判断投诉是否成立</span>
        </div>

        <n-spin :show="chatLoading">
          <n-scrollbar class="chat-box">
            <n-empty v-if="!chatLoading && chatMessages.length === 0" description="暂无聊天记录" />
            <div v-else class="message-list">
              <div
                v-for="msg in chatMessages"
                :key="msg.id"
                class="message-row"
                :class="{ right: msg.senderRole === 'defendant' }"
              >
                <div class="message-meta">
                  <span>{{ msg.senderName || '未知用户' }}</span>
                  <span>{{ msg.senderRole === 'complainant' ? '投诉人' : '被投诉人' }} · {{ msg.createTime }}</span>
                </div>
                <div class="message-bubble" :class="{ defendant: msg.senderRole === 'defendant' }">
                  <template v-if="msg.msgType === 'image'">
                    [图片] {{ msg.content }}
                  </template>
                  <template v-else>
                    {{ msg.content }}
                  </template>
                </div>
              </div>
            </div>
          </n-scrollbar>
        </n-spin>
      </div>

      <template #footer>
        <div class="review-actions">
          <n-button type="primary" :loading="actionLoading" @click="processComplaint">
            处理投诉
          </n-button>
          <n-button type="error" :loading="actionLoading" @click="rejectComplaint">
            退回投诉
          </n-button>
        </div>
      </template>
    </n-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, h } from 'vue'
import {
  NButton,
  NCard,
  NDataTable,
  NDescriptions,
  NDescriptionsItem,
  NDivider,
  NEmpty,
  NModal,
  NScrollbar,
  NSpin,
  NTag,
  useMessage,
} from 'naive-ui'
import { useUserStore } from '../../stores/user'

const message = useMessage()
const userStore = useUserStore()
const complaints = ref<any[]>([])
const showReviewModal = ref(false)
const currentComplaint = ref<any | null>(null)
const chatMessages = ref<any[]>([])
const chatLoading = ref(false)
const actionLoading = ref(false)

async function fetchComplaints() {
  const res = await fetch('/api/complaint/list', {
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  complaints.value = json.data || []
}

async function openReview(row: any) {
  currentComplaint.value = row
  chatMessages.value = []
  showReviewModal.value = true
  chatLoading.value = true
  try {
    const res = await fetch(`/api/complaint/${row.id}/chat-records`, {
      headers: { Authorization: `Bearer ${userStore.token}` },
    })
    const json = await res.json()
    if (json.code === 200) {
      currentComplaint.value = { ...row, ...json.data }
      chatMessages.value = json.data?.messages || []
    } else {
      message.error(json.msg || '聊天记录加载失败')
    }
  } catch (e: any) {
    message.error(e?.message || '聊天记录加载失败')
  } finally {
    chatLoading.value = false
  }
}

async function processComplaint() {
  if (!currentComplaint.value) return
  actionLoading.value = true
  try {
    const res = await fetch(`/api/complaint/process/${currentComplaint.value.id}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${userStore.token}` },
    })
    const json = await res.json()
    if (json.code === 200) {
      message.success('投诉已处理，已扣减被投诉人信用分')
      showReviewModal.value = false
      fetchComplaints()
    } else {
      message.error(json.msg || '操作失败')
    }
  } finally {
    actionLoading.value = false
  }
}

async function rejectComplaint() {
  if (!currentComplaint.value) return
  actionLoading.value = true
  try {
    const res = await fetch(`/api/complaint/reject/${currentComplaint.value.id}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${userStore.token}` },
    })
    const json = await res.json()
    if (json.code === 200) {
      message.success('投诉已退回')
      showReviewModal.value = false
      fetchComplaints()
    } else {
      message.error(json.msg || '操作失败')
    }
  } finally {
    actionLoading.value = false
  }
}

function getStatusText(status: number) {
  if (status === 0) return '待处理'
  if (status === 1) return '已处理'
  if (status === 2) return '已退回'
  return '未知'
}

function getStatusType(status: number) {
  if (status === 0) return 'warning'
  if (status === 1) return 'success'
  if (status === 2) return 'default'
  return 'default'
}

const columns = [
  { title: 'ID', key: 'id', width: 60 },
  { title: '投诉人', key: 'complainantName', width: 80 },
  { title: '被投诉人', key: 'defendantName', width: 80 },
  {
    title: '被投诉人信用分',
    key: 'defendantCreditScore',
    width: 120,
    render: (row: any) =>
      h(NTag, { type: row.defendantCreditScore >= 85 ? 'success' : 'error' }, { default: () => row.defendantCreditScore ?? '-' }),
  },
  { title: '原因', key: 'reason', ellipsis: { tooltip: true } },
  { title: '时间', key: 'createTime', width: 160 },
  {
    title: '状态',
    key: 'status',
    width: 90,
    render: (row: any) => h(NTag, { type: getStatusType(row.status) }, { default: () => getStatusText(row.status) }),
  },
  {
    title: '操作',
    key: 'actions',
    width: 90,
    render: (row: any) =>
      row.status === 0
        ? h(NButton, { type: 'primary', size: 'small', onClick: () => openReview(row) }, { default: () => '处理' })
        : h('span', { style: 'color: #999' }, getStatusText(row.status)),
  },
]

onMounted(() => {
  fetchComplaints()
})
</script>

<style scoped>
.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  font-size: 15px;
  font-weight: 600;
}

.chat-tip {
  color: #909399;
  font-size: 12px;
  font-weight: 400;
}

.chat-box {
  height: 360px;
  padding: 12px;
  border: 1px solid #eef0f4;
  border-radius: 8px;
  background: #f7f8fa;
}

.message-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.message-row {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.message-row.right {
  align-items: flex-end;
}

.message-meta {
  display: flex;
  gap: 8px;
  margin-bottom: 4px;
  color: #909399;
  font-size: 12px;
}

.message-bubble {
  max-width: 68%;
  padding: 9px 12px;
  border-radius: 8px;
  background: #ffffff;
  color: #303133;
  line-height: 1.6;
  word-break: break-word;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
}

.message-bubble.defendant {
  background: #e8f3ff;
}

.review-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>
