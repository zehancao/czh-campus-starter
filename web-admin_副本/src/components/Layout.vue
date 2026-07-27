<template>
  <n-layout has-sider style="height: 100vh">
    <n-layout-sider bordered :width="220" :collapsed-width="64" collapse-mode="width" show-trigger>
      <div style="padding: 16px; font-size: 18px; font-weight: bold; text-align: center; border-bottom: 1px solid #efeff5">
        校园助手管理后台
      </div>
      <n-menu :options="menuOptions" :value="currentRoute" @update:value="handleMenuClick" />
    </n-layout-sider>
    <n-layout>
      <n-layout-header bordered style="height: 56px; padding: 0 24px; display: flex; align-items: center; justify-content: space-between">
        <span style="font-size: 16px; font-weight: 500">{{ pageTitle }}</span>
        <n-space>
          <span style="color: #666">{{ userStore.userInfo?.name || '管理员' }}</span>
          <n-button text type="error" @click="handleLogout">退出</n-button>
        </n-space>
      </n-layout-header>
      <n-layout-content style="padding: 24px; background: #f5f5f5; overflow: auto">
        <router-view />
      </n-layout-content>
    </n-layout>
  </n-layout>
</template>

<script setup lang="ts">
import { computed, h } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { NLayout, NLayoutSider, NLayoutHeader, NLayoutContent, NMenu, NSpace, NButton, NIcon } from 'naive-ui'
import { useUserStore } from '../stores/user'
import {
  CalendarOutline,
  MegaphoneOutline,
  SchoolOutline,
  PeopleOutline,
  StatsChartOutline,
  BagHandleOutline,
  AlertCircleOutline,
  ShieldOutline,
} from '@vicons/ionicons5'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const menuOptions = [
  { label: '数据大屏', key: '/dashboard', icon: () => h(NIcon, null, { default: () => h(StatsChartOutline) }) },
  { label: '课表导入', key: '/schedule', icon: () => h(NIcon, null, { default: () => h(CalendarOutline) }) },
  { label: '公告管理', key: '/announcement', icon: () => h(NIcon, null, { default: () => h(MegaphoneOutline) }) },
  { label: '学期管理', key: '/semester', icon: () => h(NIcon, null, { default: () => h(SchoolOutline) }) },
  { label: '班级管理', key: '/class', icon: () => h(NIcon, null, { default: () => h(PeopleOutline) }) },
  { label: '交易审核', key: '/product', icon: () => h(NIcon, null, { default: () => h(BagHandleOutline) }) },
  { label: '投诉记录', key: '/complaint', icon: () => h(NIcon, null, { default: () => h(AlertCircleOutline) }) },
  { label: '求助记录', key: '/safety', icon: () => h(NIcon, null, { default: () => h(ShieldOutline) }) },
]

const currentRoute = computed(() => route.path)
const pageTitle = computed(() => {
  const m: Record<string, string> = { '/dashboard': '数据大屏', '/schedule': '课表导入', '/announcement': '公告管理', '/semester': '学期管理', '/class': '班级管理', '/product': '交易审核', '/complaint': '投诉记录', '/safety': '求助记录' }
  return m[route.path] || ''
})

function handleMenuClick(key: string) {
  router.push(key)
}

function handleLogout() {
  userStore.logout()
  router.push('/screen')
}
</script>
