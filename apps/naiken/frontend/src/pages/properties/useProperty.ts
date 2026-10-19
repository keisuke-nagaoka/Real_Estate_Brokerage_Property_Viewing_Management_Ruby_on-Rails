import { useEffect, useState } from 'react'
import { propertiesApi } from '../../api/properties'
import { ApiError, errorMessage } from '../../lib/api'
import type { Property } from '../../types'

export function useProperty(id: string | undefined) {
  const [property, setProperty] = useState<Property | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)

  useEffect(() => {
    if (!id) return
    let ignore = false
    propertiesApi
      .get(id)
      .then((res) => !ignore && setProperty(res.data))
      .catch((e: unknown) => {
        if (ignore) return
        if (e instanceof ApiError && e.status === 404) setNotFound(true)
        else setError(errorMessage(e))
      })
    return () => {
      ignore = true
    }
  }, [id])

  return { property, error, notFound }
}
