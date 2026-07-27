<template>
  <div class="dashboard">
    <!-- 顶部KPI指标卡片 -->
    <n-grid :cols="4" :x-gap="16" :y-gap="16">
      <!-- 注册用户：新增可点击弹窗 -->
      <n-gi>
        <n-card class="stat-card clickable" @click="openUserModal">
          <n-statistic label="注册用户" :value="overview.userCount">
            <template #prefix><span style="font-size:20px">👤</span></template>
          </n-statistic>
        </n-card>
      </n-gi>
      <!-- 商品总数：可点击弹窗 -->
      <n-gi>
        <n-card class="stat-card clickable" @click="openProductModal">
          <n-statistic label="商品总数" :value="overview.productCount">
            <template #prefix><span style="font-size:20px">📦</span></template>
          </n-statistic>
        </n-card>
      </n-gi>
      <!-- 公告数量：可点击弹窗 -->
      <n-gi>
        <n-card class="stat-card clickable" @click="openAnnounceModal">
          <n-statistic label="公告数量" :value="announcementList.length">
            <template #prefix><span style="font-size:20px">📢</span></template>
          </n-statistic>
        </n-card>
      </n-gi>
      <!-- 失物招领：点击弹窗 -->
      <n-gi>
        <n-card class="stat-card clickable" @click="openLostFoundModal">
          <n-statistic label="失物招领" :value="overview.lostFoundCount">
            <template #prefix><span style="font-size:20px">🔍</span></template>
          </n-statistic>
        </n-card>
      </n-gi>
    </n-grid>

    <!-- 图表区域：3行5列网格布局 -->
    <div class="chart-grid">
      <n-card title="商品分类分布" class="chart-card grid-item category">
        <div ref="categoryChartRef" class="chart-box"></div>
      </n-card>
      <n-card title="用户学院分布" class="chart-card grid-item college">
        <div ref="collegeChartRef" class="chart-box"></div>
      </n-card>
      <n-card title="近7日公告发布量" class="chart-card grid-item announce">
        <div ref="announceChartRef" class="chart-box"></div>
      </n-card>
      <n-card title="籍贯分布热力图" class="chart-card grid-item map">
        <div ref="mapChartRef" class="chart-box"></div>
      </n-card>
    </div>

    <!-- 【新增】注册用户列表弹窗（完全匹配users库全字段） -->
    <n-modal
      v-model:show="showUserModal"
      preset="card"
      title="全部注册用户列表"
      style="width: 1900px; max-width: 95vw"
      :mask-closable="true"
    >
      <n-data-table
        :columns="userColumns"
        :data="userList"
        :loading="userLoading"
        :bordered="false"
        :single-line="false"
        :scroll-x="2000"
        striped
      />
      <template #footer>
        <div style="text-align: right">
          <n-button @click="showUserModal = false">关闭</n-button>
        </div>
      </template>
    </n-modal>

    <!-- 失物招领详情弹窗 -->
    <n-modal
      v-model:show="showLostFoundModal"
      preset="card"
      title="失物招领列表"
      style="width: 1500px; max-width: 95vw"
      :mask-closable="true"
    >
      <n-data-table
        :columns="lostFoundColumns"
        :data="lostFoundList"
        :loading="lostFoundLoading"
        :bordered="false"
        :single-line="false"
        :scroll-x="1500"
        striped
      />
      <template #footer>
        <div style="text-align: right">
          <n-button @click="showLostFoundModal = false">关闭</n-button>
        </div>
      </template>
    </n-modal>

    <!-- 商品列表弹窗 -->
    <n-modal
      v-model:show="showProductModal"
      preset="card"
      title="全部商品列表"
      style="width: 1800px; max-width: 95vw"
      :mask-closable="true"
    >
      <n-data-table
        :columns="productColumns"
        :data="productList"
        :loading="productLoading"
        :bordered="false"
        :single-line="false"
        :scroll-x="1900"
        striped
      />
      <template #footer>
        <div style="text-align: right">
          <n-button @click="showProductModal = false">关闭</n-button>
        </div>
      </template>
    </n-modal>

    <!-- 公告列表弹窗 -->
    <n-modal
      v-model:show="showAnnounceModal"
      preset="card"
      title="全部公告列表"
      style="width: 1000px"
      :mask-closable="true"
    >
      <n-data-table
        :columns="announceColumns"
        :data="announcementList"
        :loading="false"
        :bordered="false"
        :single-line="false"
        striped
      />
      <template #footer>
        <div style="text-align: right">
          <n-button @click="showAnnounceModal = false">关闭</n-button>
        </div>
      </template>
    </n-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, onBeforeUnmount, watch, h } from 'vue'
import { NGrid, NGi, NCard, NStatistic, NModal, NDataTable, NButton, NTag, useMessage } from 'naive-ui'
import * as echarts from 'echarts'
import { useUserStore } from '../../stores/user'
import { getAnnouncements } from '../../api/admin'
import chinaJson from '../../assets/china.json'

echarts.registerMap('china', chinaJson as any)
const message = useMessage()
const userStore = useUserStore()

const overview = ref<Record<string, number>>({
  userCount: 0,
  productCount: 0,
  announcementCount: 0,
  lostFoundCount: 0,
})
const announcementList = ref<any[]>([])

// ========== 新增：注册用户弹窗变量 ==========
const showUserModal = ref(false)
const userList = ref<any[]>([])
const userLoading = ref(false)

// 失物招领弹窗
const showLostFoundModal = ref(false)
const lostFoundList = ref<any[]>([])
const lostFoundLoading = ref(false)

// 商品弹窗
const showProductModal = ref(false)
const productList = ref<any[]>([])
const productLoading = ref(false)

// 公告弹窗
const showAnnounceModal = ref(false)

// ====================== 【新增】用户表格 100%匹配users表字段 + TS类型修复 ======================
const userColumns = [
  { title: '用户ID', key: 'id', width: 70 },
  { title: '学号', key: 'student_id', width: 110 },
  { title: '姓名', key: 'name', width: 100 },
  { title: '头像', key: 'avatar', width: 140, ellipsis: { tooltip: { scrollable: true } } },
  { title: '学院', key: 'college', width: 130 },
  { title: '专业', key: 'major', width: 120 },
  { title: '年级', key: 'grade', width: 90 },
  { title: '班级ID', key: 'class_id', width: 90 },
  { title: '班级名称', key: 'class_name', width: 110 },
  { title: '手机号', key: 'phone', width: 130 },
  { title: '籍贯省份', key: 'province', width: 100 },
  { title: '家乡', key: 'hometown', width: 120, ellipsis: { tooltip: { scrollable: true } } },
  {
    title: '角色', key: 'role', width: 100,
    render: (row: any) => {
      if (!row.role) return h(NTag, { size: 'small', type: 'default' }, { default: () => '--' })
      const type = row.role === 'admin' ? 'info' : 'default'
      return h(NTag, { type, size: 'small' }, { default: () => row.role === 'student' ? '学生' : '管理员' })
    }
  },
  { title: '信用分', key: 'credit_score', width: 90 },
  {
    title: '账号状态', key: 'status', width: 100,
    render: (row: any) => {
      if (row.status == null) return h(NTag, { size: 'small', type: 'default' }, { default: () => '--' })
      const numStatus = Number(row.status)
      const map: Record<number, { text: string; type: 'success' | 'error' }> = {
        1: { text: '正常', type: 'success' },
        0: { text: '禁用', type: 'error' }
      }
      const cfg = map[numStatus] ?? { text: '未知', type: 'default' }
      return h(NTag, { type: cfg.type, size: 'small' }, { default: () => cfg.text })
    }
  },
  { title: '创建时间', key: 'create_time', width: 160 },
  { title: '更新时间', key: 'update_time', width: 160 },
]

// ====================== 失物招领表格【修复全部TS索引/类型报错】 ======================
const lostFoundColumns = [
  { title: 'ID', key: 'id', width: 70 },
  { title: '发布用户ID', key: 'user_id', width: 100 },
  {
    title: '类型', key: 'type', width: 90,
    render: (row: any) => {
      if (row.type == null) return h(NTag, { size: 'small', type: 'default' }, { default: () => '--' })
      const typeMap: Record<number, string> = { 1: '寻物', 2: '招领' }
      const numType = Number(row.type)
      const text = typeMap[numType] ?? '未知'
      const tagType: 'warning' | 'success' = numType === 1 ? 'warning' : 'success'
      return h(NTag, { type: tagType, size: 'small' }, { default: () => text })
    }
  },
  { title: '物品标题', key: 'title', width: 180, ellipsis: { tooltip: { scrollable: true, contentStyle: 'max-width:700px;max-height:50vh' } } },
  { title: '物品描述', key: 'description', ellipsis: { tooltip: { scrollable: true, contentStyle: 'max-width:800px;max-height:60vh' } } },
  {
    title: '图片', key: 'images', width: 120,
    render: (row: any) => {
      if (!row.images) return '--'
      try {
        const arr = JSON.parse(row.images)
        return Array.isArray(arr) ? arr.join('、') : String(row.images)
      } catch {
        return String(row.images)
      }
    },
    ellipsis: { tooltip: { scrollable: true } }
  },
  { title: '物品分类', key: 'category', width: 120 },
  { title: '丢失地点', key: 'location_desc', width: 160, ellipsis: { tooltip: { scrollable: true } } },
  { title: '联系电话', key: 'contact_phone', width: 140 },
  {
    title: '状态', key: 'status', width: 110,
    render: (row: any) => {
      if (row.status == null) return h(NTag, { size: 'small', type: 'default' }, { default: () => '--' })
      const statusMap: Record<number, { text: string; type: 'warning' | 'success' | 'default' }> = {
        1: { text: '寻找中', type: 'warning' },
        2: { text: '已找到/归还', type: 'success' }
      }
      const numStatus = Number(row.status)
      const cfg = statusMap[numStatus] ?? { text: '未知', type: 'default' }
      return h(NTag, { type: cfg.type, size: 'small' }, { default: () => cfg.text })
    }
  },
  { title: '发布时间', key: 'create_time', width: 180 },
]

// ====================== 商品表格【同步修复全部TS索引/字面量类型报错】 ======================
const productColumns = [
  { title: '商品ID', key: 'id', width: 70 },
  { title: '卖家ID', key: 'seller_id', width: 90 },
  { title: '分类ID', key: 'category_id', width: 90 },
  { title: '商品标题', key: 'title', width: 220, ellipsis: { tooltip: { scrollable: true, contentStyle: 'max-width:700px' } } },
  { title: '商品描述', key: 'description', ellipsis: { tooltip: { scrollable: true, contentStyle: 'max-width:800px;max-height:60vh' } } },
  { title: '售价', key: 'price', width: 90 },
  { title: '原价', key: 'original_price', width: 90 },
  {
    title: '成色', key: 'condition_level', width: 110,
    render: (row: any) => {
      if (row.condition_level == null) return h(NTag, { size: 'small', type: 'default' }, { default: () => '--' })
      const levelMap: Record<number, string> = { 1: '全新', 2: '几乎全新', 3: '有使用痕迹' }
      const numLevel = Number(row.condition_level)
      const text = levelMap[numLevel] ?? '未知成色'
      return h(NTag, { size: 'small' }, { default: () => text })
    }
  },
  {
    title: '商品状态', key: 'status', width: 100,
    render: (row: any) => {
      if (row.status == null) return h(NTag, { size: 'small', type: 'default' }, { default: () => '--' })
      const statusMap: Record<number, { text: string; type: 'success' | 'info' | 'warning' | 'default' }> = {
        1: { text: '在售', type: 'success' },
        2: { text: '已售', type: 'info' },
        3: { text: '下架', type: 'warning' }
      }
      const numStatus = Number(row.status)
      const cfg = statusMap[numStatus] ?? { text: '未知', type: 'default' }
      return h(NTag, { type: cfg.type, size: 'small' }, { default: () => cfg.text })
    }
  },
  { title: '浏览量', key: 'view_count', width: 80 },
  { title: '收藏数', key: 'favorite_count', width: 80 },
  { title: '交易地点', key: 'campus_location', width: 130, ellipsis: { tooltip: { scrollable: true } } },
  {
    title: '商品图片', key: 'images', width: 120,
    render: (row: any) => {
      if (!row.images) return '--'
      try {
        const arr = JSON.parse(row.images)
        return Array.isArray(arr) ? arr.join('、') : String(row.images)
      } catch {
        return String(row.images)
      }
    },
    ellipsis: { tooltip: { scrollable: true } }
  },
  {
    title: '商品标签', key: 'tags', width: 120,
    render: (row: any) => {
      if (!row.tags) return '--'
      try {
        const arr = JSON.parse(row.tags)
        return Array.isArray(arr) ? arr.join('、') : String(row.tags)
      } catch {
        return String(row.tags)
      }
    },
    ellipsis: { tooltip: { scrollable: true } }
  },
  { title: '创建时间', key: 'create_time', width: 160 },
  { title: '更新时间', key: 'update_time', width: 160 },
]

// 公告表格
const announceColumns = [
  { title: 'ID', key: 'id', width: 70 },
  { title: '标题', key: 'title', width: 280, ellipsis: { tooltip: { scrollable: true } } },
  {
    title: '分类', key: 'category', width: 100,
    render: (row: any) => h(NTag, { size: 'small' }, { default: () => row.category || '--' })
  },
  {
    title: '置顶', key: 'isTop', width: 90,
    render: (row: any) => h(NTag, { type: row.isTop ? 'info' : 'default', size: 'small' }, { default: () => row.isTop ? '置顶' : '普通' })
  },
  {
    title: '状态', key: 'isPublished', width: 100,
    render: (row: any) => h(NTag, { type: row.isPublished ? 'success' : 'warning', size: 'small' }, { default: () => row.isPublished ? '已发布' : '草稿' })
  },
  { title: '发布时间', key: 'publishTime', width: 160 },
]

const categoryChartRef = ref<HTMLElement | null>(null)
const collegeChartRef = ref<HTMLElement | null>(null)
const announceChartRef = ref<HTMLElement | null>(null)
const mapChartRef = ref<HTMLElement | null>(null)

let categoryChart: echarts.ECharts | null = null
let collegeChart: echarts.ECharts | null = null
let announceChart: echarts.ECharts | null = null
let mapChart: echarts.ECharts | null = null

function getLast7Days(): string[] {
  const days: string[] = []
  const today = new Date()
  for (let i = 6; i >= 0; i--) {
    const date = new Date(today)
    date.setDate(today.getDate() - i)
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    days.push(`${month}-${day}`)
  }
  return days
}

// ========== 弹窗打开函数（新增用户弹窗打开逻辑） ==========
async function openUserModal() {
  showUserModal.value = true
  await loadUserList()
}
async function openLostFoundModal() {
  showLostFoundModal.value = true
  await loadLostFoundList()
}
async function openProductModal() {
  showProductModal.value = true
  await loadProductList()
}
function openAnnounceModal() {
  showAnnounceModal.value = true
}

// ========== 新增：加载注册用户列表接口 ==========
async function loadUserList() {
  userLoading.value = true
  try {
    const res = await fetch('/api/admin/user/list', {
      headers: { Authorization: `Bearer ${userStore.token}` },
    })
    const json = await res.json()
    userList.value = json.data || []
  } catch (e) {
    console.error('加载用户列表失败', e)
    message.warning('注册用户明细接口暂未开发')
  } finally {
    userLoading.value = false
  }
}

// 加载失物招领列表
async function loadLostFoundList() {
  lostFoundLoading.value = true
  try {
    const res = await fetch('/api/admin/lost-found/list', {
      headers: { Authorization: `Bearer ${userStore.token}` },
    })
    const json = await res.json()
    lostFoundList.value = json.data || []
  } catch (e) {
    console.error('加载失物招领失败', e)
    message.warning('失物招领明细接口暂未开发')
  } finally {
    lostFoundLoading.value = false
  }
}

// 加载商品列表
async function loadProductList() {
  productLoading.value = true
  try {
    const res = await fetch('/api/admin/product/list', {
      headers: { Authorization: `Bearer ${userStore.token}` },
    })
    const json = await res.json()
    productList.value = json.data || []
  } catch (e) {
    console.error('加载商品列表失败', e)
    message.warning('商品明细接口暂未开发')
  } finally {
    productLoading.value = false
  }
}

async function fetchStats(path: string) {
  const res = await fetch(`/api/admin/stats${path}`, {
    headers: { Authorization: `Bearer ${userStore.token}` },
  })
  const json = await res.json()
  return json.data
}

function calcWeekCount(list: any[]) {
  const dateList = getLast7Days()
  const counts = new Array(7).fill(0)
  list.forEach(item => {
    const time = item.publishTime || item.createTime
    if (!time) return
    const md = time.slice(5, 10)
    const idx = dateList.indexOf(md)
    if (idx > -1) counts[idx]++
  })
  return counts
}

const renderAnnounceChart = () => {
  if (!announceChartRef.value) return
  if (!announceChart) announceChart = echarts.init(announceChartRef.value)
  const data = calcWeekCount(announcementList.value)
  const dateList = getLast7Days()
  const option = {
    tooltip: { trigger: 'axis' },
    backgroundColor: 'transparent',
    textStyle: { color: '#000000', fontSize: 13 },
    xAxis: {
      type: 'category',
      data: dateList,
      axisLine: { lineStyle: { color: '#2a3450' } },
      axisLabel: { color: '#000000', fontSize: 12 }
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: '#eeeeee' } },
      axisLabel: { color: '#000000', fontSize: 12 }
    },
    series: [{
      data: data,
      type: 'bar',
      barWidth: '40%',
      itemStyle: { borderRadius: [4, 4, 0, 0], color: '#3a7bd5' }
    }]
  }
  announceChart.setOption(option)
}

async function loadAnnouncementList() {
  const res = await getAnnouncements()
  announcementList.value = res.data || []
}

function resizeCharts() {
  categoryChart?.resize()
  collegeChart?.resize()
  announceChart?.resize()
  mapChart?.resize()
}

onMounted(async () => {
  const ov = await fetchStats('/overview')
  if (ov) overview.value = ov

  await loadAnnouncementList()
  await nextTick()

  // 商品分类饼图
  const catData = await fetchStats('/products-by-category')
  if (categoryChartRef.value && catData) {
    categoryChart = echarts.init(categoryChartRef.value)
    categoryChart.setOption({
      tooltip: { trigger: 'item' },
      backgroundColor: 'transparent',
      textStyle: { color: '#000000', fontSize: 13 },
      legend: { orient: 'vertical', left: 10, top: 'center', textStyle: { color: '#000000', fontSize: 12 }, itemGap: 12 },
      series: [{
        type: 'pie',
        radius: ['40%', '65%'],
        center: ['65%', '50%'],
        data: catData,
        emphasis: { itemStyle: { shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0,0,0,0.5)' } },
      }],
    })
  }

  // 用户学院柱状图
  const collegeData = await fetchStats('/users-by-college')
  if (collegeChartRef.value && collegeData) {
    collegeChart = echarts.init(collegeChartRef.value)
    collegeChart.setOption({
      tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
      backgroundColor: 'transparent',
      textStyle: { color: '#000000', fontSize: 13 },
      xAxis: {
        type: 'category',
        data: collegeData.map((d: { name: string; value: number }) => d.name || '未填写'),
        axisLine: { lineStyle: { color: '#2a3450' } },
        axisLabel: { color: '#000000', fontSize: 11, rotate: 0, interval: 0, overflow: 'break', align: 'center' }
      },
      yAxis: {
        type: 'value',
        splitLine: { lineStyle: { color: '#eeeeee' } },
        axisLabel: { color: '#000000', fontSize: 12 }
      },
      series: [{
        type: 'bar',
        data: collegeData.map((d: { name: string; value: number }) => d.value),
        barWidth: '40%',
        itemStyle: { borderRadius: [4, 4, 0, 0], color: '#3a7bd5' }
      }],
    })
  }

  renderAnnounceChart()

  // 籍贯热力地图
  const hometownData = await fetchStats('/hometown-stats')
  if (mapChartRef.value && hometownData) {
    const nameFix: Record<string, string> = {
      '北京': '北京市', '天津': '天津市', '上海': '上海市', '重庆': '重庆市',
      '河北': '河北省', '山西': '山西省', '辽宁': '辽宁省', '吉林': '吉林省', '黑龙江': '黑龙江省',
      '江苏': '江苏省', '浙江': '浙江省', '安徽': '安徽省', '福建': '福建省', '江西': '江西省', '山东': '山东省',
      '河南': '河南省', '湖北': '湖北省', '湖南': '湖南省', '广东': '广东省', '海南': '海南省',
      '四川': '四川省', '贵州': '贵州省', '云南': '云南省', '陕西': '陕西省',
      '甘肃': '甘肃省', '青海': '青海省', '台湾': '台湾省',
    }
    const mapData = hometownData.map((item: { name: string; value: number | null | undefined }) => ({
      name: nameFix[item.name] || item.name,
      value: Number(item.value) || 0,
    }))
    mapChart = echarts.init(mapChartRef.value)
    const validValues = mapData.map((item: { name: string; value: number }) => item.value).filter((v: number) => !isNaN(v))
    const maxVal = validValues.length ? Math.max(...validValues) : 1
    mapChart.setOption({
      tooltip: {
        trigger: 'item',
        formatter: (params: any) => {
          const val = Number(params.data?.value) || 0
          return `${params.name}: ${val}人`
        },
      },
      backgroundColor: 'transparent',
      textStyle: { color: '#000000', fontSize: 13 },
      visualMap: {
        min: 0,
        max: maxVal,
        text: ['多', '少'],
        textStyle: { color: '#000000', fontSize: 12 },
        inRange: { color: ['#ffffff', '#3a7bd5', '#4ecb71', '#f0c040', '#ff6b6b'] },
        calculable: true,
        left: 'left',
        itemWidth: 16,
        itemHeight: 130,
      },
      series: [{
        type: 'map',
        map: 'china',
        roam: true,
        zoom: 1.3,
        layoutCenter: ['50%', '58%'],
        layoutSize: '80%',
        label: { show: true, fontSize: 11, color: '#000000' },
        itemStyle: { borderColor: '#cccccc', borderWidth: 1, areaColor: '#ffffff' },
        emphasis: { label: { show: true, fontSize: 13 }, itemStyle: { areaColor: '#f0f9ff' } },
        data: mapData,
      }],
    })
  }

  window.addEventListener('resize', resizeCharts)
})

watch(announcementList, () => {
  renderAnnounceChart()
}, { deep: true })

onBeforeUnmount(() => {
  window.removeEventListener('resize', resizeCharts)
  categoryChart?.dispose()
  collegeChart?.dispose()
  announceChart?.dispose()
  mapChart?.dispose()
})
</script>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.dashboard {
  width: 100%;
  padding: 20px;
  background: #ffffff;
  color: #000000;
  font-family: 'Segoe UI', 'PingFang SC', Roboto, 'Helvetica Neue', sans-serif;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.chart-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  grid-template-rows: repeat(3, 1fr);
  gap: 16px;
  min-height: 0;
}

.grid-item {
  min-height: 0;
  display: flex;
  flex-direction: column;
}
.category { grid-row: 1 / 2; grid-column: 1 / 3; }
.college { grid-row: 2 / 3; grid-column: 1 / 3; }
.announce { grid-row: 3 / 4; grid-column: 1 / 3; }
.map { grid-row: 1 / 4; grid-column: 3 / 6; }

.stat-card {
  background: #ffffff !important;
  border: 1px solid #e5e7eb !important;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s, box-shadow 0.2s;
}
.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: #d1d5db !important;
}
.stat-card.clickable { cursor: pointer; }
.stat-card.clickable:hover {
  border-color: #3a7bd5 !important;
  box-shadow: 0 4px 16px rgba(58, 123, 213, 0.15);
}
.stat-card :deep(.n-card__header) { color: #000000 !important; font-weight: 500; }
.stat-card :deep(.n-statistic__label) { color: #666666 !important; font-size: 14px; }
.stat-card :deep(.n-statistic__value) { color: #000000 !important; font-size: 32px; font-weight: 600; }

.chart-card {
  background: #ffffff !important;
  border: 1px solid #e5e7eb !important;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}
.chart-card :deep(.n-card__header) {
  background: #ffffff !important;
  border-bottom: 1px solid #f0f0f0;
  flex-shrink: 0;
}
.chart-card :deep(.n-card__content) { flex: 1; min-height: 0; }
.chart-card :deep(.n-card__header),
.chart-card :deep(.n-card__header-main),
.chart-card :deep(.n-card__title),
.chart-card :deep(.n-card__header span),
.chart-card :deep(.n-card__title span) {
  color: #ff6b6b !important;
  font-size: 16px;
  font-weight: 500;
  padding-left: 8px;
  border-left: none;
}

.chart-box {
  width: 100%;
  height: 100%;
}
</style>