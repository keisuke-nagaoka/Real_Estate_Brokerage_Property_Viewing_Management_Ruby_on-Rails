import { useState } from 'react'
import { Link } from 'react-router'
import { viewingsApi } from '../api/viewings'
import { errorMessage } from '../lib/api'
import { formatDateLabel, formatTime, toDateInput } from '../lib/datetime'
import { viewingStatusLabels } from '../lib/labels'
import type { Viewing } from '../types'

type Props = {
  viewings: Viewing[]
  onChange: (viewing: Viewing) => void
  hideCustomer?: boolean
  hideProperty?: boolean
  emptyMessage?: string
}

// 内見予定を日付ごとにまとめて表示し、予定に対する操作(実施済み・キャンセル・編集)を提供する
export function ViewingList({ viewings, onChange, hideCustomer, hideProperty, emptyMessage = '内見予定はありません' }: Props) {
  const [error, setError] = useState<string | null>(null)
  const [busyId, setBusyId] = useState<number | null>(null)
  // 「実施済みにする」ボタンは開始時刻を過ぎた予定にだけ出す(表示時点の時刻で判定する)
  const [now] = useState(() => Date.now())

  const run = async (viewing: Viewing, action: 'complete' | 'cancel') => {
    if (action === 'cancel' && !window.confirm(`${formatDateLabel(viewing.starts_at)} ${formatTime(viewing.starts_at)}〜の内見予定をキャンセルしますか？`)) {
      return
    }
    setBusyId(viewing.id)
    setError(null)
    try {
      const res = action === 'complete' ? await viewingsApi.complete(viewing.id) : await viewingsApi.cancel(viewing.id)
      onChange(res.data)
    } catch (e) {
      setError(errorMessage(e))
    } finally {
      setBusyId(null)
    }
  }

  if (viewings.length === 0) {
    return <p className="card empty">{emptyMessage}</p>
  }

  const groups = groupByDate(viewings)

  return (
    <div className="viewing-list">
      {error && <p className="alert alert-error">{error}</p>}
      {groups.map(([date, items]) => (
        <section key={date} className="viewing-group">
          <h3 className="viewing-date">{formatDateLabel(items[0].starts_at)}</h3>
          <div className="card viewing-items">
            {items.map((viewing) => (
              <div key={viewing.id} className={`viewing-item is-${viewing.status}`}>
                <div className="viewing-time">
                  {formatTime(viewing.starts_at)}
                  <span className="muted small">〜{formatTime(viewing.ends_at)}</span>
                </div>
                <div className="viewing-body">
                  <div className="viewing-title">
                    {!hideCustomer && (
                      <Link to={`/customers/${viewing.customer.id}`} className="link-strong">
                        {viewing.customer.name}
                      </Link>
                    )}
                    {!hideCustomer && !hideProperty && <span className="muted"> × </span>}
                    {!hideProperty && (
                      <Link to={`/properties/${viewing.property.id}`} className="link-strong">
                        {viewing.property.name}
                      </Link>
                    )}
                  </div>
                  <div className="muted small">
                    担当: {viewing.agent.name}
                    {!hideProperty && ` ／ ${viewing.property.address}`}
                  </div>
                  {viewing.note && <div className="small pre-wrap">{viewing.note}</div>}
                </div>
                <span className={`badge badge-${viewing.status}`}>{viewingStatusLabels[viewing.status]}</span>
                <div className="viewing-actions">
                  {viewing.status === 'scheduled' && (
                    <>
                      {new Date(viewing.starts_at).getTime() <= now && (
                        <button type="button" className="btn btn-small" disabled={busyId === viewing.id} onClick={() => run(viewing, 'complete')}>
                          実施済みにする
                        </button>
                      )}
                      <Link to={`/viewings/${viewing.id}/edit`} className="btn btn-small">
                        編集
                      </Link>
                      <button type="button" className="btn btn-small btn-danger" disabled={busyId === viewing.id} onClick={() => run(viewing, 'cancel')}>
                        キャンセル
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}
          </div>
        </section>
      ))}
    </div>
  )
}

function groupByDate(viewings: Viewing[]): [string, Viewing[]][] {
  const groups = new Map<string, Viewing[]>()
  for (const viewing of viewings) {
    const key = toDateInput(viewing.starts_at)
    groups.set(key, [...(groups.get(key) ?? []), viewing])
  }
  return [...groups.entries()]
}
