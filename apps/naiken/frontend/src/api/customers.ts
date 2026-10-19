import { api } from '../lib/api'
import type { Customer, CustomerInput, Paginated, Single } from '../types'

export type CustomerQuery = {
  q?: string
  agent_id?: string
  page?: number
  per_page?: number
}

export const customersApi = {
  list: (query: CustomerQuery) => api.get<Paginated<Customer>>('/customers', query),
  get: (id: number | string) => api.get<Single<Customer>>(`/customers/${id}`),
  create: (input: CustomerInput) => api.post<Single<Customer>>('/customers', { customer: input }),
  update: (id: number | string, input: CustomerInput) => api.patch<Single<Customer>>(`/customers/${id}`, { customer: input }),
  delete: (id: number | string) => api.delete(`/customers/${id}`),
}
