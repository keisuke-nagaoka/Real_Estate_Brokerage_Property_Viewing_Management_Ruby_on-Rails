export type Agent = {
  id: number
  name: string
  email: string
}

export type Customer = {
  id: number
  name: string
  name_kana: string
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
