import { useEffect, useState, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router'
import { agentsApi } from '../../api/agents'
import { customersApi } from '../../api/customers'
import { Pagination } from '../../components/Pagination'
import { errorMessage } from '../../lib/api'
import { formatBudget, formatDateTime } from '../../lib/format'
import type { Agent, Customer, PageMeta } from '../../types'

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
  const page = Number(searchParams.get('page') ?? 1)

  const queryKey = `${q}|${agentId}|${page}`

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
    let ignore = false
    customersApi
      .list({ q, agent_id: agentId, page })
      .then((res) => !ignore && setResult({ key: queryKey, customers: res.data, meta: res.meta, error: null }))
      .catch((e: unknown) => !ignore && setResult({ key: queryKey, customers: [], meta: null, error: errorMessage(e) }))
    return () => {
      ignore = true
    }
  }, [q, agentId, page, queryKey])

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
        <Link to="/customers/new" className="btn btn-primary">
          ＋ 顧客を登録
        </Link>
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
        <select className="input select" value={agentId} onChange={(e) => updateQuery({ agent_id: e.target.value, page: '' })}>
          <option value="">すべての担当者</option>
          {agents.map((agent) => (
            <option key={agent.id} value={agent.id}>
              {agent.name}
            </option>
          ))}
        </select>
      </form>

      {error && <p className="alert alert-error">{error}</p>}

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>氏名</th>
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
                <td>{customer.agent.name}</td>
                <td>{formatBudget(customer.budget_max)}</td>
                <td>{customer.desired_area ?? '-'}</td>
                <td>{customer.phone ?? '-'}</td>
                <td className="small">{formatDateTime(customer.updated_at)}</td>
              </tr>
            ))}
            {!loading && customers.length === 0 && (
              <tr>
                <td colSpan={6} className="empty">
                  該当する顧客はいません
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {result?.meta && <Pagination meta={result.meta} onChange={(next) => updateQuery({ page: String(next) })} />}
    </div>
  )
}
