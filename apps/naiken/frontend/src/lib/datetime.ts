// 内見は日本国内の業務のため、ブラウザのタイムゾーンに関係なく日本時間で扱う
const TIME_ZONE = 'Asia/Tokyo'

function parts(date: Date): Record<string, string> {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  })
  return Object.fromEntries(formatter.formatToParts(date).map((p) => [p.type, p.value]))
}

// "YYYY-MM-DD"
export function toDateInput(date: Date | string): string {
  const p = parts(new Date(date))
  return `${p.year}-${p.month}-${p.day}`
}

// "HH:MM"
export function toTimeInput(date: Date | string): string {
  const p = parts(new Date(date))
  return `${p.hour}:${p.minute}`
}

// 日付と時刻の入力値から、日本時間のオフセット付きISO文字列を作る
export function toIso(date: string, time: string): string {
  return date && time ? `${date}T${time}:00+09:00` : ''
}

export function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000)
}

// "10月20日(火)"
export function formatDateLabel(iso: string): string {
  return new Date(iso).toLocaleDateString('ja-JP', { timeZone: TIME_ZONE, month: 'long', day: 'numeric', weekday: 'short' })
}

export function formatTime(iso: string): string {
  return toTimeInput(iso)
}
