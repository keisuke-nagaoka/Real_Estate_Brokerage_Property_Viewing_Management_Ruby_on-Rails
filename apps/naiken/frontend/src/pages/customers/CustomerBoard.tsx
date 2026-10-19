import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { customersApi } from '../../api/customers'
import { errorMessage } from '../../lib/api'
import { formatBudget } from '../../lib/format'
import { customerStatuses, customerStatusLabels } from '../../lib/labels'
import type { Customer, CustomerStatus } from '../../types'

type Column = { status: CustomerStatus; customers: Customer[]; total: number }

type BoardResult = {
  key: string
  columns: Column[]
  error: string | null
}

const PER_COLUMN = 50

// 対応ステータスごとに顧客を並べるボード表示。列ごとにAPIへ問い合わせ、件数は列の見出しに出す
export function CustomerBoard({ q, agentId }: { q: string; agentId: string }) {
  const queryKey = `${q}|${agentId}`
  const [result, setResult] = useState<BoardResult | null>(null)
  const loading = result?.key !== queryKey

  useEffect(() => {
    let ignore = false
    Promise.all(customerStatuses.map((status) => customersApi.list({ q, agent_id: agentId, status, per_page: PER_COLUMN })))
      .then((responses) => {
        if (ignore) return
        const columns = responses.map((res, i) => ({ status: customerStatuses[i], customers: res.data, total: res.meta.total_count }))
        setResult({ key: queryKey, columns, error: null })
      })
      .catch((e: unknown) => !ignore && setResult({ key: queryKey, columns: [], error: errorMessage(e) }))
    return () => {
      ignore = true
    }
  }, [q, agentId, queryKey])

  if (result?.error) return <p className="alert alert-error">{result.error}</p>

  return (
    <div className={`board${loading ? ' loading' : ''}`}>
      {(result?.columns ?? []).map((column) => (
        <section key={column.status} className={`board-column board-cs-${column.status}`}>
          <header className="board-column-header">
            <span>{customerStatusLabels[column.status]}</span>
            <span className="board-count">{column.total}</span>
          </header>
          <div className="board-cards">
            {column.customers.map((customer) => (
              <Link key={customer.id} to={`/customers/${customer.id}`} className="board-card">
                <div className="board-card-name">{customer.name}</div>
                <div className="muted small">{customer.name_kana}</div>
                <div className="small">
                  {formatBudget(customer.budget_max)}
                  {customer.desired_area && ` ／ ${customer.desired_area}`}
                </div>
                <div className="muted small">担当: {customer.agent.name}</div>
              </Link>
            ))}
            {column.customers.length === 0 && <p className="board-empty">該当なし</p>}
            {column.total > column.customers.length && <p className="board-empty">ほか {column.total - column.customers.length} 件</p>}
          </div>
        </section>
      ))}
    </div>
  )
}
