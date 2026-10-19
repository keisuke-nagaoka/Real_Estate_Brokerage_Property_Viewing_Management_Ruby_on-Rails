import { useEffect, useState } from 'react'
import { customersApi } from '../../api/customers'
import { ApiError, errorMessage } from '../../lib/api'
import type { Customer } from '../../types'

export function useCustomer(id: string | undefined) {
  const [customer, setCustomer] = useState<Customer | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)

  useEffect(() => {
    if (!id) return
    let ignore = false
    customersApi
      .get(id)
      .then((res) => !ignore && setCustomer(res.data))
      .catch((e: unknown) => {
        if (ignore) return
        if (e instanceof ApiError && e.status === 404) setNotFound(true)
        else setError(errorMessage(e))
      })
    return () => {
      ignore = true
    }
  }, [id])

  return { customer, error, notFound }
}
