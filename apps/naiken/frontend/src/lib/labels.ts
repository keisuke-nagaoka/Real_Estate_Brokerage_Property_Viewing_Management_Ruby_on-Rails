import type { CustomerStatus, PropertyStatus, ViewingStatus } from '../types'

export const propertyStatusLabels: Record<PropertyStatus, string> = {
  available: '掲載中',
  closed: '掲載終了',
}

export const viewingStatusLabels: Record<ViewingStatus, string> = {
  scheduled: '予定',
  completed: '実施済み',
  canceled: 'キャンセル',
}
// 画面上の並び順(案件の進み具合の順)
export const customerStatuses: CustomerStatus[] = ['inquiry', 'viewing_scheduled', 'considering', 'contracted', 'lost']

export const customerStatusLabels: Record<CustomerStatus, string> = {
  inquiry: '問い合わせ',
  viewing_scheduled: '内見予定',
  considering: '検討中',
  contracted: '成約',
  lost: '失注',
}

// 成約・失注は案件が終了した状態(内見予定を追加できない)
export const closedCustomerStatuses: CustomerStatus[] = ['contracted', 'lost']

