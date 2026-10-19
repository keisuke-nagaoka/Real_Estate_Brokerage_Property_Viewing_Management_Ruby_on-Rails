import { api } from '../lib/api'
import type { List, Paginated, Property, PropertyArea, PropertyInput, Single } from '../types'

export type PropertyQuery = {
  q?: string
  prefecture?: string
  city?: string
  status?: string
  price_min?: string
  price_max?: string
  page?: number
  per_page?: number
}

export const propertiesApi = {
  list: (query: PropertyQuery) => api.get<Paginated<Property>>('/properties', query),
  areas: () => api.get<List<PropertyArea>>('/properties/areas'),
  get: (id: number | string) => api.get<Single<Property>>(`/properties/${id}`),
  create: (input: PropertyInput) => api.post<Single<Property>>('/properties', { property: input }),
  update: (id: number | string, input: PropertyInput) => api.patch<Single<Property>>(`/properties/${id}`, { property: input }),
  delete: (id: number | string) => api.delete(`/properties/${id}`),
  uploadPhotos: (id: number, files: File[]) => {
    const form = new FormData()
    files.forEach((file) => form.append('photos[]', file))
    return api.post<Single<Property>>(`/properties/${id}/photos`, form)
  },
  deletePhoto: (id: number, photoId: number) => api.deleteWithResponse<Single<Property>>(`/properties/${id}/photos/${photoId}`),
}
