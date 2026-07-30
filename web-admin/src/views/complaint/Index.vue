<template>
  <div>
    <n-card title="投诉记录">
      <n-empty v-if="complaints.length === 0" description="暂无投诉记录" />
      <n-data-table v-else :columns="columns" :data="complaints" :bordered="false" />
    </n-card>

    <n-modal
      v-model:show="showImagePreview"
      preset="card"
      :bordered="false"
      style="width: auto; max-width: 90vw"
      :show-cancel="false"
      :show-confirm="false"
    >
      <img :src="previewImageUrl" style="max-width: 100%; max-height: 70vh; display: block; margin: 0 auto" />
    </n-modal>

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
                    <img
                      :src="normalizeImageUrl(msg.content)"
                      class="chat-image"
                      @click="previewImage(normalizeImageUrl(msg.content))"
                    />
                  </template>
                  <template v-else-if="msg.msgType === 'product'">
                    <div class="product-card">
                      <img
                        v-if="parseProductCard(msg.content).image"
                        :src="normalizeImageUrl(parseProductCard(msg.content).image)"
                        class="product-card-img"
                      />
                      <div v-else class="product-card-placeholder">商</div>
                      <div class="product-card-info">
                        <div class="product-card-title">{{ parseProductCard(msg.content).title || '商品卡片' }}</div>
                        <div class="product-card-price">¥{{ parseProductCard(msg.content).price.toFixed(2) }}</div>
                      </div>
                    </div>
                  </template>
                  <template v-else-if="msg.msgType === 'video'">
                    <div class="video-card">
                      <span class="video-icon">▶</span>
                      <div class="video-info">
                        <div>视频</div>
                        <div class="video-sub">已发送视频文件</div>
                      </div>
                    </div>
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
const showImagePreview = ref(false)
const previewImageUrl = ref('')

function normalizeImageUrl(url: string) {
  if (!url) return ''
  if (url.startsWith('http')) return url
  return url
}

function parseProductCard(content: string) {
  try {
    const obj = JSON.parse(content)
    return {
      productId: obj.productId ?? 0,
      title: obj.title || '',
      price: typeof obj.price === 'number' ? obj.price : parseFloat(obj.price) || 0,
      image: obj.image || '',
      status: obj.status ?? 1,
    }
  } catch {
    return { productId: 0, title: content, price: 0, image: '', status: 1 }
  }
}

function previewImage(url: string) {
  previewImageUrl.value = url
  showImagePreview.value = true
}

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

.chat-image {
  max-width: 200px;
  max-height: 200px;
  border-radius: 8px;
  cursor: pointer;
  object-fit: cover;
}

.product-card {
  display: flex;
  gap: 10px;
  padding: 8px;
  background: #fff;
  border-radius: 8px;
  border: 1px solid #ebeef5;
  min-width: 220px;
}

.product-card-img {
  width: 56px;
  height: 56px;
  border-radius: 6px;
  object-fit: cover;
  flex-shrink: 0;
}

.product-card-placeholder {
  width: 56px;
  height: 56px;
  border-radius: 6px;
  background: #ecf5ff;
  color: #409eff;
  font-size: 22px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.product-card-info {
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-width: 0;
}

.product-card-title {
  font-size: 13px;
  color: #303133;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 150px;
}

.product-card-price {
  font-size: 13px;
  color: #f56c6c;
  font-weight: 600;
  margin-top: 4px;
}

.video-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background: #fff;
  border-radius: 8px;
  border: 1px solid #ebeef5;
}

.video-icon {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #ecf5ff;
  color: #409eff;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.video-info div:first-child {
  font-size: 14px;
  font-weight: 500;
  color: #303133;
}

.video-sub {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.review-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>
