import { api } from '../lib/api'
import type { Customer, CustomerInput, CustomerStatus, Paginated, Single } from '../types'

export type CustomerQuery = {
  q?: string
  agent_id?: string
  status?: string
  page?: number
  per_page?: number
}

export const customersApi = {
  list: (query: CustomerQuery) => api.get<Paginated<Customer>>('/customers', query),
  get: (id: number | string) => api.get<Single<Customer>>(`/customers/${id}`),
  create: (input: CustomerInput) => api.post<Single<Customer>>('/customers', { customer: input }),
  update: (id: number | string, input: CustomerInput) => api.patch<Single<Customer>>(`/customers/${id}`, { customer: input }),
  delete: (id: number | string) => api.delete(`/customers/${id}`),
  changeStatus: (id: number, status: CustomerStatus) =>
    api.patch<Single<Customer> & { meta: { canceled_viewings_count: number } }>(`/customers/${id}/status`, { status }),
}
