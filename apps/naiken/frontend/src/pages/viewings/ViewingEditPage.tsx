import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router'
import { viewingsApi } from '../../api/viewings'
import { ApiError, errorMessage } from '../../lib/api'
import type { Viewing } from '../../types'
import { NotFoundPage } from '../NotFoundPage'
import { ViewingForm } from './ViewingForm'

export function ViewingEditPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [viewing, setViewing] = useState<Viewing | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)

  useEffect(() => {
    if (!id) return
    let ignore = false
    viewingsApi
      .get(id)
      .then((res) => !ignore && setViewing(res.data))
      .catch((e: unknown) => {
        if (ignore) return
        if (e instanceof ApiError && e.status === 404) setNotFound(true)
        else setError(errorMessage(e))
      })
    return () => {
      ignore = true
    }
  }, [id])

  if (notFound) return <NotFoundPage />

  return (
    <div className="page narrow">
      <header className="page-header">
        <h1>内見予定を編集</h1>
      </header>
      {error && <p className="alert alert-error">{error}</p>}
      {viewing && viewing.status !== 'scheduled' && <p className="alert alert-error">実施済み・キャンセル済みの内見予定は変更できません</p>}
      {viewing && viewing.status === 'scheduled' && (
        <ViewingForm
          initial={viewing}
          submitLabel="更新する"
          onSubmit={async (input) => {
            await viewingsApi.update(viewing.id, input)
            navigate(-1)
          }}
          onCancel={() => navigate(-1)}
        />
      )}
    </div>
  )
}
