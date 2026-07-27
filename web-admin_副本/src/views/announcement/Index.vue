<template>
  <n-card title="公告管理">
    <n-space vertical :size="16">
      <n-button type="primary" @click="showModal = true; editId = null; resetForm()">发布公告</n-button>

      <n-table :bordered="true" :single-line="false" size="small">
        <thead>
          <tr>
            <th>标题</th>
            <th>分类</th>
            <th>置顶</th>
            <th>状态</th>
            <th>发布时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in announcements" :key="item.id">
            <td>{{ item.title }}</td>
            <td><n-tag size="small">{{ item.category }}</n-tag></td>
            <td>{{ item.isTop ? '是' : '否' }}</td>
            <td>{{ item.isPublished ? '已发布' : '草稿' }}</td>
            <td>{{ item.publishTime || item.createTime }}</td>
            <td>
              <n-space>
                <n-button text type="primary" @click="handleEdit(item)">编辑</n-button>
                <n-popconfirm @positive-click="handleDelete(item.id)">
                  <template #trigger><n-button text type="error">删除</n-button></template>
                  确定删除此公告？
                </n-popconfirm>
              </n-space>
            </td>
          </tr>
        </tbody>
      </n-table>

      <n-empty v-if="!announcements.length" description="暂无公告" />
    </n-space>

    <n-modal v-model:show="showModal" :title="editId ? '编辑公告' : '发布公告'" preset="card" style="width: 700px">
      <n-form :model="form" label-placement="top">
        <n-form-item label="标题">
          <n-input v-model:value="form.title" placeholder="公告标题" />
        </n-form-item>
        <n-form-item label="分类">
          <n-select v-model:value="form.category" :options="categoryOptions" />
        </n-form-item>
        <n-form-item label="内容">
          <n-input v-model:value="form.content" type="textarea" :rows="8" placeholder="公告内容" />
        </n-form-item>
        <n-form-item label="摘要">
          <n-input v-model:value="form.summary" placeholder="摘要（可选）" />
        </n-form-item>
        <n-form-item label="置顶">
          <n-switch v-model:value="form.isTopBool" />
        </n-form-item>
        <n-form-item label="立即发布">
          <n-switch v-model:value="form.isPublishedBool" />
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
import { NCard, NSpace, NButton, NTable, NTag, NEmpty, NModal, NForm, NFormItem, NInput, NSelect, NSwitch, NPopconfirm, useMessage } from 'naive-ui'
import { getAnnouncements, publishAnnouncement, updateAnnouncement, deleteAnnouncement } from '../../api/admin'

const message = useMessage()
const announcements = ref<any[]>([])
const showModal = ref(false)
const submitting = ref(false)
const editId = ref<number | null>(null)

const categoryOptions = [
  { label: '教务', value: '教务' },
  { label: '学工', value: '学工' },
  { label: '社团', value: '社团' },
  { label: '后勤', value: '后勤' },
  { label: '紧急', value: '紧急' },
]

const form = reactive({
  title: '',
  content: '',
  summary: '',
  category: '教务',
  isTopBool: false,
  isPublishedBool: true,
})

function resetForm() {
  form.title = ''
  form.content = ''
  form.summary = ''
  form.category = '教务'
  form.isTopBool = false
  form.isPublishedBool = true
}

onMounted(loadData)

async function loadData() {
  try {
    const res: any = await getAnnouncements()
    announcements.value = res.data || []
  } catch (e: any) {
    message.error('加载公告失败')
  }
}

function handleEdit(item: any) {
  editId.value = item.id
  form.title = item.title
  form.content = item.content
  form.summary = item.summary || ''
  form.category = item.category
  form.isTopBool = !!item.isTop
  form.isPublishedBool = !!item.isPublished
  showModal.value = true
}

async function handleSubmit() {
  if (!form.title || !form.content) {
    message.warning('标题和内容不能为空')
    return
  }
  submitting.value = true
  try {
    const data = {
      title: form.title,
      content: form.content,
      summary: form.summary,
      category: form.category,
      isTop: form.isTopBool ? 1 : 0,
      isPublished: form.isPublishedBool ? 1 : 0,
    }
    if (editId.value) {
      await updateAnnouncement(editId.value, data)
      message.success('更新成功')
    } else {
      await publishAnnouncement(data)
      message.success('发布成功')
    }
    showModal.value = false
    loadData()
  } catch (e: any) {
    message.error(e.message || '操作失败')
  } finally {
    submitting.value = false
  }
}

async function handleDelete(id: number) {
  try {
    await deleteAnnouncement(id)
    message.success('删除成功')
    loadData()
  } catch (e: any) {
    message.error('删除失败')
  }
}
</script>
