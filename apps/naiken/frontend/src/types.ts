export type Agent = {
  id: number
  name: string
  email: string
}

export type CustomerStatus = 'inquiry' | 'viewing_scheduled' | 'considering' | 'contracted' | 'lost'

export type Customer = {
  id: number
  name: string
  name_kana: string
  status: CustomerStatus
  next_statuses: CustomerStatus[]
  email: string | null
  phone: string | null
  budget_max: number | null
  desired_area: string | null
  note: string | null
  agent: Agent
  created_at: string
  updated_at: string
}

export type CustomerInput = {
  agent_id: number | ''
  name: string
  name_kana: string
  email: string
  phone: string
  budget_max: number | ''
  desired_area: string
  note: string
}

export type PageMeta = {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

export type Single<T> = { data: T }
export type List<T> = { data: T[] }
export type Paginated<T> = { data: T[]; meta: PageMeta }

export type PropertyStatus = 'available' | 'closed'

// 物件があるエリア(絞り込みの選択肢)
export type PropertyArea = {
  prefecture: string
  count: number
  cities: { name: string; count: number }[]
}

export type Property = {
  id: number
  name: string
  prefecture: string
  city: string
  address_line: string
  // 都道府県・市区町村・町名番地をつなげた表示用の住所
  address: string
  price: number
  layout: string | null
  floor_area: number | null
  built_year: number | null
  nearest_station: string | null
  walk_minutes: number | null
  status: PropertyStatus
  note: string | null
  created_at: string
  updated_at: string
}

export type PropertyInput = {
  name: string
  prefecture: string
  city: string
  address_line: string
  price: number | ''
  layout: string
  floor_area: number | ''
  built_year: number | ''
  nearest_station: string
  walk_minutes: number | ''
  status: PropertyStatus
  note: string
}

export type ViewingStatus = 'scheduled' | 'completed' | 'canceled'

export type Viewing = {
  id: number
  starts_at: string
  ends_at: string
  status: ViewingStatus
  note: string | null
  customer: { id: number; name: string }
  property: { id: number; name: string; address: string }
  agent: { id: number; name: string }
  created_at: string
  updated_at: string
}

export type ViewingInput = {
  customer_id: number | ''
  property_id: number | ''
  agent_id: number | ''
  starts_at: string
  ends_at: string
  note: string
}
