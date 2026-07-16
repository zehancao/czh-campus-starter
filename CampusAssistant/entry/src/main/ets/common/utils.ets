/**
 * 通用工具函数
 */

/**
 * HSL 色相生成：根据课程 ID hash 生成固定色相值
 * 保证同一门课在不同周颜色一致，相邻色相差距 ≥ 30°
 */
export function generateHue(courseId: number, courseName: string): number {
  const str = `${courseId}_${courseName}`
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i)
    hash |= 0
  }
  // 取绝对值，映射到 0-360，步进 30°
  const hue = Math.abs(hash) % 12 * 30
  return hue
}

/**
 * HSL 转 Hex 颜色
 */
export function hslToHex(h: number, s: number, l: number): string {
  s /= 100
  l /= 100
  const a = s * Math.min(l, 1 - l)
  const f = (n: number) => {
    const k = (n + h / 30) % 12
    const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1)
    return Math.round(255 * color).toString(16).padStart(2, '0')
  }
  return `#${f(0)}${f(8)}${f(4)}`
}

/**
 * 格式化日期
 */
export function formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
  const year = date.getFullYear().toString()
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const day = date.getDate().toString().padStart(2, '0')
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')

  return format
    .replace('YYYY', year)
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
}

/**
 * 节次索引转时间字符串
 */
export function periodToTime(periodNum: number, isStart: boolean): string {
  const TIMES = [
    ['08:30', '09:15'], ['09:20', '10:05'], ['10:25', '11:10'],
    ['11:15', '12:00'], ['14:30', '15:15'], ['15:20', '16:05'],
    ['16:25', '17:10'], ['17:15', '18:00'], ['19:00', '19:45'],
    ['19:50', '20:35']
  ]
  const idx = periodNum - 1
  if (idx < 0 || idx >= TIMES.length) return ''
  return isStart ? TIMES[idx][0] : TIMES[idx][1]
}
