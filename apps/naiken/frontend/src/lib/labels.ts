import type { PropertyStatus, ViewingStatus } from '../types'

export const propertyStatusLabels: Record<PropertyStatus, string> = {
  available: '掲載中',
  closed: '掲載終了',
}

export const viewingStatusLabels: Record<ViewingStatus, string> = {
  scheduled: '予定',
  completed: '実施済み',
  canceled: 'キャンセル',
}
