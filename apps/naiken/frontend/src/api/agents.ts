import { api } from '../lib/api'
import type { Agent, List } from '../types'

export const agentsApi = {
  list: () => api.get<List<Agent>>('/agents'),
}
