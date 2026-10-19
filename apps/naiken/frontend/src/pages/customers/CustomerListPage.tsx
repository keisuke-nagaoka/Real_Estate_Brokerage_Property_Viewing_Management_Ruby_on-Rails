import { useEffect, useState, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router'
import { agentsApi } from '../../api/agents'
import { customersApi } from '../../api/customers'
import { CustomerStatusBadge } from '../../components/CustomerStatusBadge'
import { Pagination } from '../../components/Pagination'
import { errorMessage } from '../../lib/api'
import { formatBudget, formatDateTime } from '../../lib/format'
import { customerStatuses, customerStatusLabels } from '../../lib/labels'
import type { Agent, Customer, PageMeta } from '../../types'
import { CustomerBoard } from './CustomerBoard'

type ListResult = {
  key: string
  customers: Customer[]
  meta: PageMeta | null
  error: string | null
}

export function CustomerListPage() {
  // 検索条件はURLのクエリに持たせ、リロードやブラウザバックでも条件を保持する
  const [searchParams, setSearchParams] = useSearchParams()
  const q = searchParams.get('q') ?? ''
  const agentId = searchParams.get('agent_id') ?? ''
  const status = searchParams.get('status') ?? ''
  const page = Number(searchParams.get('page') ?? 1)
  const view = searchParams.get('view') === 'board' ? 'board' : 'list'
  const queryKey = `${q}|${agentId}|${status}|${page}`

  const [agents, setAgents] = useState<Agent[]>([])
  const [agentsError, setAgentsError] = useState<string | null>(null)
  // 取得結果は「どの検索条件の結果か(key)」と一緒に保持し、条件と一致しない間を読み込み中とみなす
  const [result, setResult] = useState<ListResult | null>(null)
  const loading = result?.key !== queryKey
  const customers = result?.customers ?? []
  const error = agentsError ?? result?.error ?? null

  useEffect(() => {
    agentsApi.list().then((res) => setAgents(res.data)).catch((e: unknown) => setAgentsError(errorMessage(e)))
  }, [])

  useEffect(() => {
    // ボード表示のときは CustomerBoard が列ごとに取得する
    if (view === 'board') return
    let ignore = false
    customersApi
      .list({ q, agent_id: agentId, status, page })
      .then((res) => !ignore && setResult({ key: queryKey, customers: res.data, meta: res.meta, error: null }))
      .catch((e: unknown) => !ignore && setResult({ key: queryKey, customers: [], meta: null, error: errorMessage(e) }))
    return () => {
      ignore = true
    }
  }, [q, agentId, status, page, queryKey, view])

  const updateQuery = (next: Record<string, string>) => {
    const params = new URLSearchParams(searchParams)
    for (const [key, value] of Object.entries(next)) {
      if (value) params.set(key, value)
      else params.delete(key)
    }
    setSearchParams(params)
  }

  const handleSearch = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const keyword = String(new FormData(e.currentTarget).get('q') ?? '')
    updateQuery({ q: keyword.trim(), page: '' })
  }

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>顧客</h1>
          <p className="muted">担当している顧客の一覧・検索</p>
        </div>
        <div className="actions">
          <div className="segmented">
            <button type="button" className={view === 'list' ? 'active' : undefined} onClick={() => updateQuery({ view: '' })}>
              一覧
            </button>
            <button type="button" className={view === 'board' ? 'active' : undefined} onClick={() => updateQuery({ view: 'board', status: '', page: '' })}>
              ステータス別
            </button>
          </div>
          <Link to="/customers/new" className="btn btn-primary">
            ＋ 顧客を登録
          </Link>
        </div>
      </header>

      <form className="toolbar" onSubmit={handleSearch}>
        {/* key に検索語を渡し、ブラウザバック等でURLの条件が変わったら入力欄も作り直す */}
        <input
          key={q}
          type="search"
          name="q"
          className="input"
          placeholder="氏名・フリガナ・メール・電話番号で検索"
          defaultValue={q}
        />
        <button type="submit" className="btn">
          検索
        </button>
        {view === 'list' && (
          <select className="input select" value={status} onChange={(e) => updateQuery({ status: e.target.value, page: '' })} aria-label="ステータス">
            <option value="">すべてのステータス</option>
            {customerStatuses.map((value) => (
              <option key={value} value={value}>
                {customerStatusLabels[value]}
              </option>
            ))}
          </select>
        )}
        <select className="input select" value={agentId} onChange={(e) => updateQuery({ agent_id: e.target.value, page: '' })} aria-label="担当者">
          <option value="">すべての担当者</option>
          {agents.map((agent) => (
            <option key={agent.id} value={agent.id}>
              {agent.name}
            </option>
          ))}
        </select>
      </form>

      {view === 'board' && <CustomerBoard q={q} agentId={agentId} />}

      {view === 'list' && error && <p className="alert alert-error">{error}</p>}

      {view === 'list' && (
        <div className="card">
          <table className="table">
            <thead>
              <tr>
                <th>氏名</th>
                <th>ステータス</th>
                <th>担当者</th>
                <th>予算上限</th>
                <th>希望エリア</th>
                <th>電話番号</th>
                <th>更新日時</th>
              </tr>
            </thead>
            <tbody className={loading ? 'loading' : undefined}>
              {customers.map((customer) => (
                <tr key={customer.id}>
                  <td>
                    <Link to={`/customers/${customer.id}`} className="link-strong">
                      {customer.name}
                    </Link>
                    <div className="muted small">{customer.name_kana}</div>
                  </td>
                  <td>
                    <CustomerStatusBadge status={customer.status} />
                  </td>
                  <td>{customer.agent.name}</td>
                  <td>{formatBudget(customer.budget_max)}</td>
                  <td>{customer.desired_area ?? '-'}</td>
                  <td>{customer.phone ?? '-'}</td>
                  <td className="small">{formatDateTime(customer.updated_at)}</td>
                </tr>
              ))}
              {!loading && customers.length === 0 && (
                <tr>
                  <td colSpan={7} className="empty">
                    該当する顧客はいません
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {view === 'list' && result?.meta && <Pagination meta={result.meta} onChange={(next) => updateQuery({ page: String(next) })} />}
    </div>
  )
}
