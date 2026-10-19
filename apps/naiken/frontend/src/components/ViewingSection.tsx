import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { viewingsApi, type ViewingQuery } from '../api/viewings'
import { errorMessage } from '../lib/api'
import type { Viewing } from '../types'
import { ViewingList } from './ViewingList'

type Props = {
  query: Pick<ViewingQuery, 'customer_id' | 'property_id'>
  addLink?: string
  hideCustomer?: boolean
  hideProperty?: boolean
  onChange?: (viewing: Viewing) => void
}

// 顧客・物件の詳細画面に表示する内見予定の一覧
export function ViewingSection({ query, addLink, hideCustomer, hideProperty, onChange }: Props) {
  const [viewings, setViewings] = useState<Viewing[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const { customer_id, property_id } = query

  useEffect(() => {
    let ignore = false
    viewingsApi
      .list({ customer_id, property_id, order: 'desc', per_page: 100 })
      .then((res) => !ignore && setViewings(res.data))
      .catch((e: unknown) => !ignore && setError(errorMessage(e)))
    return () => {
      ignore = true
    }
  }, [customer_id, property_id])

  const replace = (updated: Viewing) => {
    setViewings((prev) => prev?.map((v) => (v.id === updated.id ? updated : v)) ?? null)
    onChange?.(updated)
  }

  return (
    <section className="section">
      <div className="section-header">
        <h2>内見予定</h2>
        {addLink && (
          <Link to={addLink} className="btn btn-primary btn-small">
            ＋ 内見予定を追加
          </Link>
        )}
      </div>
      {error && <p className="alert alert-error">{error}</p>}
      {viewings && <ViewingList viewings={viewings} onChange={replace} hideCustomer={hideCustomer} hideProperty={hideProperty} />}
    </section>
  )
}
