import { api } from '../lib/api'
import type { Paginated, Single, Viewing, ViewingInput } from '../types'

export type ViewingQuery = {
  from?: string
  to?: string
  agent_id?: string | number
  customer_id?: string | number
  property_id?: string | number
  status?: string
  order?: 'asc' | 'desc'
  page?: number
  per_page?: number
}

export const viewingsApi = {
  list: (query: ViewingQuery) => api.get<Paginated<Viewing>>('/viewings', query),
  get: (id: number | string) => api.get<Single<Viewing>>(`/viewings/${id}`),
  create: (input: ViewingInput) => api.post<Single<Viewing>>('/viewings', { viewing: input }),
  update: (id: number | string, input: ViewingInput) => api.patch<Single<Viewing>>(`/viewings/${id}`, { viewing: input }),
  complete: (id: number) => api.patch<Single<Viewing>>(`/viewings/${id}/complete`),
  cancel: (id: number) => api.patch<Single<Viewing>>(`/viewings/${id}/cancel`),
}
