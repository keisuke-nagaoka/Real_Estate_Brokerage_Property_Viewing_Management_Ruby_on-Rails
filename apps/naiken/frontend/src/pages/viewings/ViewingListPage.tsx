import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router'
import { agentsApi } from '../../api/agents'
import { viewingsApi, type ViewingQuery } from '../../api/viewings'
import { Pagination } from '../../components/Pagination'
import { ViewingList } from '../../components/ViewingList'
import { errorMessage } from '../../lib/api'
import { addDays, toDateInput } from '../../lib/datetime'
import type { Agent, PageMeta, Viewing } from '../../types'

type Tab = 'upcoming' | 'past'

type ListResult = {
  key: string
  viewings: Viewing[]
  meta: PageMeta | null
  error: string | null
}

const tabs: { value: Tab; label: string }[] = [
  { value: 'upcoming', label: '今日以降の予定' },
  { value: 'past', label: '過去の履歴' },
]

export function ViewingListPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const tab: Tab = searchParams.get('tab') === 'past' ? 'past' : 'upcoming'
  const agentId = searchParams.get('agent_id') ?? ''
  const page = Number(searchParams.get('page') ?? 1)
  const queryKey = `${tab}|${agentId}|${page}`

  const [agents, setAgents] = useState<Agent[]>([])
  // 取得結果は「どの検索条件の結果か(key)」と一緒に保持し、条件と一致しない間を読み込み中とみなす
  const [result, setResult] = useState<ListResult | null>(null)
  const loading = result?.key !== queryKey

  useEffect(() => {
    agentsApi.list().then((res) => setAgents(res.data))
  }, [])

  useEffect(() => {
    let ignore = false
    const today = new Date()
    const query: ViewingQuery =
      tab === 'upcoming'
        ? { from: toDateInput(today), order: 'asc', agent_id: agentId, page }
        : { to: toDateInput(addDays(today, -1)), order: 'desc', agent_id: agentId, page }
    viewingsApi
      .list(query)
      .then((res) => !ignore && setResult({ key: queryKey, viewings: res.data, meta: res.meta, error: null }))
      .catch((e: unknown) => !ignore && setResult({ key: queryKey, viewings: [], meta: null, error: errorMessage(e) }))
    return () => {
      ignore = true
    }
  }, [tab, agentId, page, queryKey])

  const updateQuery = (next: Record<string, string>) => {
    const params = new URLSearchParams(searchParams)
    for (const [key, value] of Object.entries(next)) {
      if (value) params.set(key, value)
      else params.delete(key)
    }
    setSearchParams(params)
  }

  const replace = (updated: Viewing) =>
    setResult((prev) => prev && { ...prev, viewings: prev.viewings.map((v) => (v.id === updated.id ? updated : v)) })

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>内見予定</h1>
          <p className="muted">顧客と物件の内見スケジュール</p>
        </div>
        <Link to="/viewings/new" className="btn btn-primary">
          ＋ 内見予定を登録
        </Link>
      </header>

      <div className="toolbar">
        <div className="segmented">
          {tabs.map((option) => (
            <button
              key={option.value}
              type="button"
              className={tab === option.value ? 'active' : undefined}
              onClick={() => updateQuery({ tab: option.value === 'upcoming' ? '' : option.value, page: '' })}
            >
              {option.label}
            </button>
          ))}
        </div>
        <select className="input select" value={agentId} onChange={(e) => updateQuery({ agent_id: e.target.value, page: '' })}>
          <option value="">すべての担当者</option>
          {agents.map((agent) => (
            <option key={agent.id} value={agent.id}>
              {agent.name}
            </option>
          ))}
        </select>
      </div>

      {result?.error && <p className="alert alert-error">{result.error}</p>}
      {result && !result.error && (
        <div className={loading ? 'loading' : undefined}>
          <ViewingList viewings={result.viewings} onChange={replace} />
        </div>
      )}

      {result?.meta && <Pagination meta={result.meta} onChange={(next) => updateQuery({ page: String(next) })} />}
    </div>
  )
}
