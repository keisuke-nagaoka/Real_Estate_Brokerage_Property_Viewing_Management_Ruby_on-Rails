export function formatBudget(manYen: number | null): string {
  return manYen === null ? '-' : `${manYen.toLocaleString('ja-JP')}万円`
}

export function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', { dateStyle: 'medium', timeStyle: 'short' })
}

// 万円単位の価格を「5,980万円」「1億2,000万円」の形式にする
export function formatPrice(manYen: number): string {
  const oku = Math.floor(manYen / 10000)
  const man = manYen % 10000
  if (oku === 0) return `${man.toLocaleString('ja-JP')}万円`
  return man === 0 ? `${oku}億円` : `${oku}億${man.toLocaleString('ja-JP')}万円`
}

export function formatBuildingAge(builtYear: number | null): string {
  if (builtYear === null) return '築年不明'
  const age = new Date().getFullYear() - builtYear
  return age <= 0 ? '新築' : `築${age}年`
}

export function formatAccess(station: string | null, walkMinutes: number | null): string {
  if (!station) return '-'
  return walkMinutes === null ? `${station}駅` : `${station}駅 徒歩${walkMinutes}分`
}
