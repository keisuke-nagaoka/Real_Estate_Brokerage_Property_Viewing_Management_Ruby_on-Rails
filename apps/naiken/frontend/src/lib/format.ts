export function formatBudget(manYen: number | null): string {
  return manYen === null ? '-' : `${manYen.toLocaleString('ja-JP')}万円`
}

export function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', { dateStyle: 'medium', timeStyle: 'short' })
}
