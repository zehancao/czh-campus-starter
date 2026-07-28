<template>
  <div class="screen">
    <!-- 动态背景：网格 + 光晕 -->
    <div class="bg-grid"></div>
    <div class="bg-orb orb-a"></div>
    <div class="bg-orb orb-b"></div>
    <div class="bg-scanline"></div>
    <canvas ref="starsRef" class="bg-stars"></canvas>
    <div class="bg-scan"></div>
    <div class="boot-bar"></div>

    <!-- 顶部标题栏 -->
    <header class="screen-header">
      <div class="hd-left">
        <span class="hd-logo">◈</span>
        <h1 class="hd-title">校园数据可视化大屏</h1>
        <span class="hd-badge">CAMPUS INSIGHT</span>
      </div>
      <div class="hd-right">
        <span class="hd-status"><i class="dot"></i>系统在线</span>
        <span class="hd-clock">{{ clock }}</span>
        <span class="hd-login" @click="goLogin">管理后台登录 ›</span>
      </div>
    </header>

    <!-- KPI 指标卡 -->
    <section class="kpi-row">
      <div class="kpi-card" v-for="k in kpis" :key="k.key" :style="{ '--accent': k.color }">
        <span class="kpi-corner tl"></span><span class="kpi-corner tr"></span>
        <span class="kpi-corner bl"></span><span class="kpi-corner br"></span>
        <div class="kpi-icon">{{ k.icon }}</div>
        <div class="kpi-body">
          <div class="kpi-value">{{ k.display }}<span class="kpi-unit">{{ k.unit }}</span></div>
          <div class="kpi-label">{{ k.label }}</div>
        </div>
        <div class="kpi-bar"></div>
      </div>
      <div class="chart-box" :style="{ '--accent': C3 }">
        <span class="kpi-corner tl"></span><span class="kpi-corner tr"></span>
        <span class="kpi-corner bl"></span><span class="kpi-corner br"></span>
        <div class="cb-title">近 7 日公告发布量</div>
        <div ref="announceChartRef" class="cb-chart"></div>
      </div>
    </section>

    <!-- 主体三栏 -->
    <section class="main-grid">
      <!-- 左栏 -->
      <div class="col col-left">
        <div class="panel">
          <div class="panel-title"><span class="bar"></span>商品分类分布</div>
          <div ref="categoryChartRef" class="panel-chart"></div>
        </div>
        <div class="panel">
          <div class="panel-title"><span class="bar"></span>用户学院分布</div>
          <div ref="collegeChartRef" class="panel-chart"></div>
        </div>
      </div>

      <!-- 中栏 -->
      <div class="col col-center">
        <div class="panel panel-map">
          <div class="panel-title"><span class="bar"></span>用户籍贯分布</div>
          <div ref="mapChartRef" class="panel-chart"></div>
        </div>
      </div>

      <!-- 右栏 -->
      <div class="col col-right">
        <div class="panel panel-feed">
          <div class="panel-title"><span class="bar"></span>最新公告动态</div>
          <div class="feed-track">
            <div class="feed-item" v-for="(a, i) in feedList" :key="i">
              <span class="feed-dot" :style="{ background: a.color }"></span>
              <div class="feed-text">
                <div class="feed-title">{{ a.title }}</div>
                <div class="feed-time">{{ a.time }}</div>
              </div>
            </div>
          </div>
        </div>
        <div class="panel">
          <div class="panel-title"><span class="bar"></span>热门分类 TOP</div>
          <div class="rank-list">
            <div class="rank-item" v-for="(c, i) in topCategories" :key="i">
              <span class="rank-no" :class="{ top: i < 3 }">{{ i + 1 }}</span>
              <span class="rank-name">{{ c.name }}</span>
              <span class="rank-val">{{ c.value }}</span>
              <span class="rank-bar"><i :style="{ width: c.pct + '%', background: rankColor }"></i></span>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import * as echarts from 'echarts'
import { useUserStore } from '../../stores/user'
import { getSensorLatest } from '../../api/admin'
import chinaJson from '../../assets/china.json'

echarts.registerMap('china', chinaJson as any)
const userStore = useUserStore()
const router = useRouter()

const C1 = '#22d3ee' // cyan
const C2 = '#6366f1' // indigo
const C3 = '#f472b6' // pink
const C4 = '#facc15' // amber
const rankColor = `linear-gradient(90deg, ${C1}, ${C2})`

const clock = ref('')
let clockTimer: any = null
function tickClock() {
  const d = new Date()
  const p = (n: number) => String(n).padStart(2, '0')
  clock.value = `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
}

function goLogin() {
  router.push('/login')
}

// ===== KPI =====
const kpis = reactive([
  { key: 'user', label: '注册用户', icon: '👤', color: C1, unit: '人', target: 0, display: 0, animate: true },
  { key: 'product', label: '商品总数', icon: '📦', color: C2, unit: '件', target: 0, display: 0, animate: true },
  { key: 'active', label: '活跃用户', icon: '⚡', color: '#34d399', unit: '人', target: 0, display: 0, animate: true },
  { key: 'lost', label: '失物招领', icon: '🔍', color: C4, unit: '条', target: 0, display: 0, animate: true },
  { key: 'temp', label: '实时温度', icon: '🌡️', color: '#fb923c', unit: '℃', target: 0, display: '--', animate: false },
  { key: 'humidity', label: '实时湿度', icon: '💧', color: '#38bdf8', unit: '%', target: 0, display: '--', animate: false },
  { key: 'light', label: '实时光照', icon: '💡', color: '#fbbf24', unit: 'lx', target: 0, display: '--', animate: false },
])

function animateCount(k: any, duration = 1500) {
  const start = performance.now()
  const from = 0
  const to = k.target || 0
  const step = (now: number) => {
    const t = Math.min(1, (now - start) / duration)
    const ease = 1 - Math.pow(1 - t, 3)
    k.display = Math.round(from + (to - from) * ease)
    if (t < 1) requestAnimationFrame(step)
  }
  requestAnimationFrame(step)
}

const announcementList = ref<any[]>([])
const feedList = ref<{ title: string; time: string; color: string }[]>([])
const topCategories = ref<{ name: string; value: number; pct: number }[]>([])

// ===== 图表实例 =====
const categoryChartRef = ref<HTMLElement | null>(null)
const collegeChartRef = ref<HTMLElement | null>(null)
const announceChartRef = ref<HTMLElement | null>(null)
const mapChartRef = ref<HTMLElement | null>(null)
let categoryChart: echarts.ECharts | null = null
let collegeChart: echarts.ECharts | null = null
let announceChart: echarts.ECharts | null = null
let mapChart: echarts.ECharts | null = null

const starsRef = ref<HTMLCanvasElement | null>(null)
let starsRAF: number | null = null

const palette = [C1, C2, C3, C4, '#34d399', '#a78bfa', '#fb923c', '#f87171', '#60a5fa', '#f0abfc']

async function fetchStats(path: string) {
  const headers: Record<string, string> = {}
  if (userStore.token) headers.Authorization = `Bearer ${userStore.token}`
  const res = await fetch(`/api/admin/stats${path}`, { headers })
  if (!res.ok) return null
  const json = await res.json()
  return json.data
}

// ===== 开发板温湿度（串口中继上报，轮询刷新）=====
let sensorTimer: any = null
async function refreshSensor() {
  try {
    const res = await getSensorLatest()
    const d = (res && res.data) || {}
    if (d.temp !== undefined && d.temp !== null) {
      const t = kpis.find(k => k.key === 'temp')
      const h = kpis.find(k => k.key === 'humidity')
      const l = kpis.find(k => k.key === 'light')
      if (t) t.display = Number(d.temp).toFixed(1)
      if (h) h.display = Number(d.humidity).toFixed(1)
      if (l && d.light !== undefined && d.light !== null) l.display = Number(d.light).toFixed(0)
    }
  } catch (e) {
    // 上报链路未接通时保留上一次数值，不闪烁
  }
}

function getLast7Days(): string[] {
  const days: string[] = []
  const today = new Date()
  for (let i = 6; i >= 0; i--) {
    const date = new Date(today)
    date.setDate(today.getDate() - i)
    days.push(`${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`)
  }
  return days
}

function buildCategory(data: any[]) {
  if (!categoryChartRef.value) return
  categoryChart = echarts.init(categoryChartRef.value)
  const total = data.reduce((s, d) => s + (d.value || 0), 0)
  categoryChart.setOption({
    tooltip: { trigger: 'item', backgroundColor: 'rgba(10,16,40,0.9)', borderColor: C1, textStyle: { color: '#e2e8f0' } },
    legend: { type: 'scroll', orient: 'vertical', right: 6, top: 'center', textStyle: { color: '#9fb3d1', fontSize: 11 }, itemWidth: 10, itemHeight: 10 },
    title: { text: total, subtext: '总数', left: '34%', top: '40%', textAlign: 'center', textStyle: { color: '#fff', fontSize: 22, fontWeight: 'bold' }, subtextStyle: { color: '#7dd3fc', fontSize: 12 } },
    series: [{
      type: 'pie', radius: ['45%', '68%'], center: ['36%', '50%'],
      avoidLabelOverlap: true, itemStyle: { borderColor: 'rgba(8,14,36,0.9)', borderWidth: 2 },
      label: { show: false }, labelLine: { show: false },
      data: data.map((d, i) => ({
        name: d.name, value: d.value,
        itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 1, 1, [{ offset: 0, color: palette[i % palette.length] }, { offset: 1, color: palette[i % palette.length] + '88' }]) },
      })),
    }],
  })
}

function buildCollege(data: any[]) {
  if (!collegeChartRef.value) return
  collegeChart = echarts.init(collegeChartRef.value)
  const list = [...data].sort((a, b) => (b.value || 0) - (a.value || 0)).slice(0, 8)
  collegeChart.setOption({
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: 'rgba(10,16,40,0.9)', borderColor: C2, textStyle: { color: '#e2e8f0' } },
    grid: { left: 10, right: 24, top: 10, bottom: 6, containLabel: true },
    xAxis: { type: 'value', axisLine: { show: false }, axisLabel: { color: '#7dd3fc', fontSize: 11 }, splitLine: { lineStyle: { color: 'rgba(120,160,220,0.12)' } } },
    yAxis: { type: 'category', data: list.map(d => d.name || '未填写'), axisLine: { lineStyle: { color: 'rgba(120,160,220,0.3)' } }, axisLabel: { color: '#cbd5e1', fontSize: 11 }, axisTick: { show: false } },
    series: [{
      type: 'bar', data: list.map(d => d.value), barWidth: '55%',
      itemStyle: { borderRadius: [0, 6, 6, 0], color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: C2 }, { offset: 1, color: C1 }]) },
      label: { show: true, position: 'right', color: '#e2e8f0', fontSize: 11 },
    }],
  })
}

function buildAnnounce() {
  if (!announceChartRef.value) return
  announceChart = echarts.init(announceChartRef.value)
  const dates = getLast7Days()
  const counts = new Array(7).fill(0)
  announcementList.value.forEach(item => {
    const time = item.publishTime || item.createTime
    if (!time) return
    const md = time.slice(5, 10)
    const idx = dates.indexOf(md)
    if (idx > -1) counts[idx]++
  })
  announceChart.setOption({
    tooltip: { trigger: 'axis', backgroundColor: 'rgba(10,16,40,0.9)', borderColor: C3, textStyle: { color: '#e2e8f0' } },
    grid: { left: 2, right: 4, top: 8, bottom: 2, containLabel: false },
    xAxis: { type: 'category', data: dates, boundaryGap: false, axisLine: { show: false }, axisTick: { show: false }, axisLabel: { color: '#7dd3fc', fontSize: 9 } },
    yAxis: { type: 'value', show: false },
    series: [{
      type: 'line', data: counts, smooth: true, symbol: 'circle', symbolSize: 7,
      lineStyle: { width: 3, color: C3, shadowColor: C3, shadowBlur: 12 },
      itemStyle: { color: '#fff', borderColor: C3, borderWidth: 2 },
      areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: C3 + '66' }, { offset: 1, color: C3 + '00' }]) },
    }],
  })
}

function buildMap(data: any[]) {
  if (!mapChartRef.value) return
  mapChart = echarts.init(mapChartRef.value)
  const nameFix: Record<string, string> = {
    '北京': '北京市', '天津': '天津市', '上海': '上海市', '重庆': '重庆市',
    '河北': '河北省', '山西': '山西省', '辽宁': '辽宁省', '吉林': '吉林省', '黑龙江': '黑龙江省',
    '江苏': '江苏省', '浙江': '浙江省', '安徽': '安徽省', '福建': '福建省', '江西': '江西省', '山东': '山东省',
    '河南': '河南省', '湖北': '湖北省', '湖南': '湖南省', '广东': '广东省', '海南': '海南省',
    '四川': '四川省', '贵州': '贵州省', '云南': '云南省', '陕西': '陕西省',
    '甘肃': '甘肃省', '青海': '青海省', '台湾': '台湾省',
  }
  const mapData = data.map(item => ({ name: nameFix[item.name] || item.name, value: Number(item.value) || 0 }))
  const maxVal = mapData.length ? Math.max(...mapData.map(d => d.value)) : 1
  mapChart.setOption({
    tooltip: { trigger: 'item', backgroundColor: 'rgba(10,16,40,0.9)', borderColor: C1, textStyle: { color: '#e2e8f0' }, formatter: (p: any) => `${p.name}: ${Number(p.data?.value) || 0}人` },
    visualMap: { min: 0, max: maxVal, text: ['多', '少'], textStyle: { color: '#cbd5e1', fontSize: 11 }, inRange: { color: ['#0b2545', '#1e3a8a', '#2563eb', '#06b6d4', '#22c55e', '#eab308', '#f97316', '#ef4444'] }, left: 10, bottom: 10, itemWidth: 14, itemHeight: 110 },
    series: [{
      type: 'map', map: 'china', roam: true, zoom: 1.15, layoutCenter: ['50%', '52%'], layoutSize: '94%',
      label: { show: false },
      itemStyle: { borderColor: 'rgba(160,220,255,0.65)', borderWidth: 1, areaColor: '#0b1b3a', shadowColor: 'rgba(0,0,0,0.6)', shadowBlur: 8 },
      emphasis: { label: { show: true, color: '#fff', fontSize: 12 }, itemStyle: { areaColor: C1 } },
      data: mapData,
    }],
  })
  mapChart?.resize()
}

function resizeCharts() {
  categoryChart?.resize(); collegeChart?.resize(); announceChart?.resize(); mapChart?.resize()
}

function initStars() {
  const cv = starsRef.value
  if (!cv) return
  const ctx = cv.getContext('2d')!
  let w = (cv.width = cv.offsetWidth)
  let h = (cv.height = cv.offsetHeight)
  const pts = Array.from({ length: 70 }, () => ({
    x: Math.random() * w,
    y: Math.random() * h,
    vx: (Math.random() - 0.5) * 0.3,
    vy: (Math.random() - 0.5) * 0.3,
    r: Math.random() * 1.6 + 0.4,
  }))
  const draw = () => {
    ctx.clearRect(0, 0, w, h)
    for (let i = 0; i < pts.length; i++) {
      const p = pts[i]
      p.x += p.vx; p.y += p.vy
      if (p.x < 0 || p.x > w) p.vx *= -1
      if (p.y < 0 || p.y > h) p.vy *= -1
      ctx.beginPath(); ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2)
      ctx.fillStyle = 'rgba(125,211,252,0.7)'; ctx.fill()
      for (let j = i + 1; j < pts.length; j++) {
        const q = pts[j]
        const dx = p.x - q.x, dy = p.y - q.y
        const d = Math.hypot(dx, dy)
        if (d < 120) {
          ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(q.x, q.y)
          ctx.strokeStyle = `rgba(99,102,241,${0.14 * (1 - d / 120)})`
          ctx.lineWidth = 1; ctx.stroke()
        }
      }
    }
    starsRAF = requestAnimationFrame(draw)
  }
  draw()
  window.addEventListener('resize', () => { w = cv.width = cv.offsetWidth; h = cv.height = cv.offsetHeight })
}

onMounted(async () => {
  tickClock()
  clockTimer = setInterval(tickClock, 1000)

  const ov = await fetchStats('/overview')
  if (ov) {
    kpis[0].target = ov.userCount || 0
    kpis[1].target = ov.productCount || 0
    kpis[2].target = ov.activeUserCount || 0
    kpis[3].target = ov.lostFoundCount || 0
  }
  const annRes = await fetch('/api/admin/announcement/list', { headers: userStore.token ? { Authorization: `Bearer ${userStore.token}` } : {} })
  const annJson = annRes.ok ? await annRes.json() : null
  announcementList.value = annJson?.data || []

  await nextTick()
  initStars()
  kpis.filter(k => k.animate).forEach(k => animateCount(k))

  // 开发板温湿度：立即拉一次 + 每 5 秒轮询刷新
  refreshSensor()
  sensorTimer = setInterval(refreshSensor, 5000)

  // 右侧动态滚动列表
  const colors = [C1, C2, C3, C4, '#34d399']
  feedList.value = announcementList.value.slice(0, 12).map((a, i) => ({
    title: a.title || '（无标题）',
    time: (a.publishTime || a.createTime || '').slice(0, 16).replace('T', ' '),
    color: colors[i % colors.length],
  }))

  // 图表
  const cat = await fetchStats('/products-by-category')
  if (cat) {
    buildCategory(cat)
    const sorted = [...cat].sort((a: any, b: any) => (b.value || 0) - (a.value || 0)).slice(0, 5)
    const max = sorted.length ? sorted[0].value : 1
    topCategories.value = sorted.map((c: any) => ({ name: c.name, value: c.value, pct: Math.round((c.value / max) * 100) }))
  }
  const col = await fetchStats('/users-by-college')
  if (col) buildCollege(col)
  buildAnnounce()
  const home = await fetchStats('/hometown-stats')
  if (home) buildMap(home)

  window.addEventListener('resize', resizeCharts)
  requestAnimationFrame(resizeCharts)
  setTimeout(resizeCharts, 300)
})

onBeforeUnmount(() => {
  clearInterval(clockTimer)
  clearInterval(sensorTimer)
  if (starsRAF) cancelAnimationFrame(starsRAF)
  window.removeEventListener('resize', resizeCharts)
  categoryChart?.dispose(); collegeChart?.dispose(); announceChart?.dispose(); mapChart?.dispose()
})
</script>

<style scoped>
.screen {
  position: relative;
  width: 100%;
  min-height: 100vh;
  padding: 16px 20px 20px;
  color: #e2e8f0;
  font-family: 'Segoe UI', 'PingFang SC', Roboto, sans-serif;
  background: radial-gradient(1200px 600px at 50% -10%, #11224d 0%, #0a1130 45%, #060a1c 100%);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.bg-grid {
  position: absolute; inset: 0; pointer-events: none; opacity: 0.25;
  background-image: linear-gradient(rgba(80,160,255,0.12) 1px, transparent 1px), linear-gradient(90deg, rgba(80,160,255,0.12) 1px, transparent 1px);
  background-size: 40px 40px;
  mask-image: radial-gradient(ellipse at 50% 0%, #000 30%, transparent 80%);
}
.bg-orb { position: absolute; border-radius: 50%; filter: blur(70px); opacity: 0.35; pointer-events: none; }
.orb-a { width: 360px; height: 360px; background: #1e40af; top: -120px; left: -80px; }
.orb-b { width: 320px; height: 320px; background: #9d174d; bottom: -120px; right: -60px; }
.bg-scanline {
  position: absolute; inset: 0; pointer-events: none; opacity: 0.06;
  background: repeating-linear-gradient(to bottom, #fff 0, #fff 1px, transparent 2px, transparent 4px);
}

/* 顶部 */
.screen-header {
  position: relative; z-index: 2;
  display: flex; align-items: center; justify-content: space-between;
  padding: 6px 4px 12px;
  border-bottom: 1px solid rgba(120,160,255,0.2);
}
.hd-left { display: flex; align-items: center; gap: 12px; }
.hd-logo { color: #22d3ee; font-size: 26px; text-shadow: 0 0 12px #22d3ee; }
.hd-title {
  margin: 0; font-size: 24px; font-weight: 800; letter-spacing: 2px;
  background: linear-gradient(90deg, #22d3ee, #818cf8, #f472b6);
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.hd-badge { font-size: 11px; color: #7dd3fc; border: 1px solid rgba(125,211,252,0.4); padding: 2px 8px; border-radius: 4px; letter-spacing: 1px; }
.hd-right { display: flex; align-items: center; gap: 18px; }
.hd-status { display: flex; align-items: center; gap: 6px; font-size: 13px; color: #9fb3d1; }
.hd-status .dot { width: 8px; height: 8px; border-radius: 50%; background: #34d399; box-shadow: 0 0 10px #34d399; animation: blink 1.6s infinite; }
.hd-clock { font-size: 15px; color: #cbd5e1; font-variant-numeric: tabular-nums; letter-spacing: 1px; }
.hd-login { font-size: 13px; color: #7dd3fc; cursor: pointer; padding: 5px 12px; border: 1px solid rgba(125,211,252,0.4); border-radius: 6px; transition: all 0.2s; letter-spacing: 1px; }
.hd-login:hover { background: rgba(125,211,252,0.15); box-shadow: 0 0 12px rgba(125,211,252,0.4); color: #e2f6ff; }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }

/* KPI：7 张卡片固定单行，压缩内部留白以适配常见大屏宽度 */
.kpi-row {
  position: relative;
  z-index: 2;
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr)) 1.6fr;
  gap: 8px;
}
.kpi-card {
  position: relative; display: flex; align-items: center; gap: 8px;
  min-width: 0; padding: 10px 10px; border-radius: 10px;
  background: linear-gradient(135deg, rgba(20,32,66,0.9), rgba(12,20,48,0.7));
  border: 1px solid color-mix(in srgb, var(--accent) 45%, transparent);
  box-shadow: 0 0 0 1px rgba(255,255,255,0.03), 0 8px 24px rgba(0,0,0,0.35);
  overflow: hidden;
}
.kpi-card::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 3px;
  background: var(--accent); box-shadow: 0 0 14px var(--accent);
}
.kpi-icon {
  width: 38px; height: 38px; flex: 0 0 38px; display: grid; place-items: center;
  font-size: 20px; border-radius: 9px;
  background: color-mix(in srgb, var(--accent) 18%, transparent);
  border: 1px solid color-mix(in srgb, var(--accent) 50%, transparent);
  box-shadow: 0 0 14px color-mix(in srgb, var(--accent) 35%, transparent);
}
.kpi-body { display: flex; flex-direction: column; min-width: 0; }
.kpi-value { font-size: 22px; font-weight: 800; color: #fff; line-height: 1.1; white-space: nowrap; text-shadow: 0 0 16px color-mix(in srgb, var(--accent) 60%, transparent); font-variant-numeric: tabular-nums; }
.kpi-unit { font-size: 10px; color: #94a3b8; margin-left: 2px; font-weight: 500; }
.kpi-label { font-size: 10px; color: #9fb3d1; margin-top: 3px; letter-spacing: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.kpi-bar { position: absolute; left: 0; right: 0; bottom: 0; height: 2px; background: linear-gradient(90deg, transparent, var(--accent), transparent); opacity: 0.7; }
.kpi-corner { position: absolute; width: 10px; height: 10px; border: 2px solid var(--accent); opacity: 0.8; }
.kpi-corner.tl { top: 6px; left: 6px; border-right: none; border-bottom: none; }
.kpi-corner.tr { top: 6px; right: 6px; border-left: none; border-bottom: none; }
.kpi-corner.bl { bottom: 6px; left: 6px; border-right: none; border-top: none; }
.kpi-corner.br { bottom: 6px; right: 6px; border-left: none; border-top: none; }

/* 主体网格 */
.main-grid { position: relative; z-index: 2; flex: 1; display: grid; grid-template-columns: 0.85fr 2.4fr 0.85fr; gap: 14px; min-height: 0; }
.col { display: flex; flex-direction: column; gap: 14px; min-height: 0; }
.col-center { min-height: 0; }
.panel {
  position: relative; flex: 1; display: flex; flex-direction: column; min-height: 0;
  border-radius: 12px; padding: 12px 14px 6px;
  background: linear-gradient(160deg, rgba(18,28,60,0.85), rgba(10,16,40,0.7));
  border: 1px solid rgba(120,160,255,0.18);
  box-shadow: inset 0 0 30px rgba(40,90,180,0.08), 0 6px 20px rgba(0,0,0,0.3);
}
.panel-map { flex: 3.6; }
.chart-box {
  position: relative; display: flex; flex-direction: column; justify-content: center; gap: 6px;
  padding: 14px 16px 10px; border-radius: 12px;
  background: linear-gradient(135deg, rgba(20,32,66,0.9), rgba(12,20,48,0.7));
  border: 1px solid color-mix(in srgb, var(--accent) 45%, transparent);
  box-shadow: 0 0 0 1px rgba(255,255,255,0.03), 0 8px 24px rgba(0,0,0,0.35);
  overflow: hidden;
}
.chart-box::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 3px;
  background: var(--accent); box-shadow: 0 0 14px var(--accent);
}
.chart-box::after {
  content: ''; position: absolute; inset: 0; border-radius: 12px; padding: 1px; pointer-events: none;
  background: conic-gradient(from var(--bd-angle), transparent 0%, color-mix(in srgb, var(--accent) 85%, transparent) 22%, transparent 52%);
  -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  -webkit-mask-composite: xor; mask-composite: exclude;
  animation: bdSpin 5s linear infinite; opacity: 0.6;
}
.cb-title { font-size: 13px; color: #9fb3d1; letter-spacing: 1px; }
.cb-chart { width: 100%; height: 80px; }
.panel-feed { flex: 1.2; }
.panel-title {
  display: flex; align-items: center; gap: 8px; font-size: 15px; font-weight: 600; color: #e2e8f0;
  padding-bottom: 8px; margin-bottom: 6px; border-bottom: 1px solid rgba(120,160,255,0.15);
}
.panel-title .bar { width: 4px; height: 16px; border-radius: 2px; background: linear-gradient(#22d3ee, #6366f1); box-shadow: 0 0 10px #22d3ee; }
.panel-chart { flex: 1; min-height: 0; width: 100%; }

/* 滚动动态 */
.feed-track { flex: 1; min-height: 0; overflow: hidden; position: relative; }
.feed-item { display: flex; gap: 10px; align-items: flex-start; padding: 9px 6px; border-bottom: 1px dashed rgba(120,160,255,0.12); animation: feedIn 0.5s ease both; }
@keyframes feedIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }
.feed-dot { width: 8px; height: 8px; border-radius: 50%; margin-top: 5px; flex: 0 0 8px; box-shadow: 0 0 8px currentColor; }
.feed-text { flex: 1; min-width: 0; }
.feed-title { font-size: 13px; color: #e2e8f0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.feed-time { font-size: 11px; color: #7dd3fc; margin-top: 3px; font-variant-numeric: tabular-nums; }

/* TOP 排行 */
.rank-list { flex: 1; display: flex; flex-direction: column; justify-content: space-around; padding: 4px 2px; }
.rank-item { display: grid; grid-template-columns: 26px 1fr auto; align-items: center; gap: 8px; font-size: 13px; }
.rank-no { width: 22px; height: 22px; display: grid; place-items: center; border-radius: 6px; font-weight: 700; color: #cbd5e1; background: rgba(120,160,255,0.12); }
.rank-no.top { color: #0a1130; background: linear-gradient(135deg, #22d3ee, #6366f1); box-shadow: 0 0 10px rgba(34,211,238,0.6); }
.rank-name { color: #e2e8f0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.rank-val { color: #fbbf24; font-weight: 700; }
.rank-bar { grid-column: 1 / -1; height: 4px; border-radius: 2px; background: rgba(120,160,255,0.12); overflow: hidden; margin-top: 4px; }
.rank-bar i { display: block; height: 100%; border-radius: 2px; }

/* ===== 未来感增强 ===== */
@property --bd-angle { syntax: '<angle>'; initial-value: 0deg; inherits: false; }

.bg-stars { position: absolute; inset: 0; width: 100%; height: 100%; z-index: 1; pointer-events: none; }

.bg-scan {
  position: absolute; left: 0; right: 0; top: 0; height: 160px; z-index: 1; pointer-events: none;
  background: linear-gradient(180deg, transparent, rgba(34,211,238,0.10) 45%, rgba(34,211,238,0.25) 50%, rgba(34,211,238,0.10) 55%, transparent);
  animation: scanMove 6s linear infinite;
}
@keyframes scanMove { 0% { transform: translateY(-180px); } 100% { transform: translateY(100vh); } }

.boot-bar {
  position: absolute; top: 0; left: 0; height: 3px; width: 0; z-index: 6; pointer-events: none;
  background: linear-gradient(90deg, #22d3ee, #6366f1, #f472b6);
  box-shadow: 0 0 14px #22d3ee;
  animation: boot 1.8s ease-out forwards;
}
@keyframes boot { 0% { width: 0; opacity: 1; } 85% { width: 100%; opacity: 1; } 100% { width: 100%; opacity: 0; } }

.panel::after {
  content: ''; position: absolute; inset: 0; border-radius: 12px; padding: 1px; pointer-events: none;
  background: conic-gradient(from var(--bd-angle), transparent 0%, rgba(34,211,238,0.85) 15%, rgba(99,102,241,0.85) 32%, transparent 55%);
  -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  -webkit-mask-composite: xor; mask-composite: exclude;
  animation: bdSpin 5s linear infinite; opacity: 0.7;
}
@keyframes bdSpin { to { --bd-angle: 360deg; } }

.kpi-card::after {
  content: ''; position: absolute; inset: 0; border-radius: 12px; padding: 1px; pointer-events: none;
  background: conic-gradient(from var(--bd-angle), transparent 0%, color-mix(in srgb, var(--accent) 85%, transparent) 22%, transparent 52%);
  -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  -webkit-mask-composite: xor; mask-composite: exclude;
  animation: bdSpin 5s linear infinite; opacity: 0.6;
}

.hd-title { animation: titlePulse 3.5s ease-in-out infinite; }
@keyframes titlePulse {
  0%, 100% { filter: drop-shadow(0 0 6px rgba(34,211,238,0.4)); }
  50% { filter: drop-shadow(0 0 18px rgba(129,140,248,0.85)); }
}

.kpi-value { animation: valPulse 2.6s ease-in-out infinite; }
@keyframes valPulse {
  0%, 100% { text-shadow: 0 0 12px color-mix(in srgb, var(--accent) 50%, transparent); }
  50% { text-shadow: 0 0 24px color-mix(in srgb, var(--accent) 85%, transparent); }
}
</style>
