import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import { customersApi } from '../../api/customers'
import { errorMessage } from '../../lib/api'
import { formatBudget, formatDateTime } from '../../lib/format'
import { NotFoundPage } from '../NotFoundPage'
import { useCustomer } from './useCustomer'

export function CustomerDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { customer, error, notFound } = useCustomer(id)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  if (notFound) return <NotFoundPage />

  const handleDelete = async () => {
    if (!customer || !window.confirm(`「${customer.name}」を削除しますか？この操作は取り消せません。`)) return
    try {
      await customersApi.delete(customer.id)
      navigate('/customers')
    } catch (e) {
      setDeleteError(errorMessage(e))
    }
  }

  return (
    <div className="page narrow">
      <p>
        <Link to="/customers" className="muted">
          ← 顧客一覧
        </Link>
      </p>
      {(error || deleteError) && <p className="alert alert-error">{error ?? deleteError}</p>}
      {customer && (
        <>
          <header className="page-header">
            <div>
              <h1>{customer.name}</h1>
              <p className="muted">{customer.name_kana}</p>
            </div>
            <div className="actions">
              <Link to={`/customers/${customer.id}/edit`} className="btn">
                編集
              </Link>
              <button type="button" className="btn btn-danger" onClick={handleDelete}>
                削除
              </button>
            </div>
          </header>

          <section className="card">
            <dl className="detail">
              <dt>担当者</dt>
              <dd>{customer.agent.name}</dd>
              <dt>メールアドレス</dt>
              <dd>{customer.email ?? '-'}</dd>
              <dt>電話番号</dt>
              <dd>{customer.phone ?? '-'}</dd>
              <dt>予算上限</dt>
              <dd>{formatBudget(customer.budget_max)}</dd>
              <dt>希望エリア</dt>
              <dd>{customer.desired_area ?? '-'}</dd>
              <dt>メモ</dt>
              <dd className="pre-wrap">{customer.note || '-'}</dd>
              <dt>登録日時</dt>
              <dd>{formatDateTime(customer.created_at)}</dd>
              <dt>更新日時</dt>
              <dd>{formatDateTime(customer.updated_at)}</dd>
            </dl>
          </section>
        </>
      )}
    </div>
  )
}
