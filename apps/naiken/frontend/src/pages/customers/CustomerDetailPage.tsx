import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import { customersApi } from '../../api/customers'
import { CustomerStatusBadge } from '../../components/CustomerStatusBadge'
import { CustomerStatusChanger } from '../../components/CustomerStatusChanger'
import { ViewingSection } from '../../components/ViewingSection'
import { errorMessage } from '../../lib/api'
import { formatBudget, formatDateTime } from '../../lib/format'
import { closedCustomerStatuses, customerStatusLabels } from '../../lib/labels'
import type { Customer } from '../../types'
import { NotFoundPage } from '../NotFoundPage'
import { useCustomer } from './useCustomer'

export function CustomerDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { customer, setCustomer, reload, error, notFound } = useCustomer(id)
  const [deleteError, setDeleteError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  // ステータス変更で内見予定がキャンセルされることがあるため、内見予定の一覧を読み直すためのキー
  const [viewingsVersion, setViewingsVersion] = useState(0)

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

  const handleStatusChanged = (updated: Customer, canceledViewingsCount: number) => {
    setCustomer(updated)
    setViewingsVersion((v) => v + 1)
    const canceled = canceledViewingsCount > 0 ? `（予定中の内見予定 ${canceledViewingsCount} 件をキャンセルしました）` : ''
    setNotice(`ステータスを「${customerStatusLabels[updated.status]}」に変更しました${canceled}`)
  }

  const isClosed = customer ? closedCustomerStatuses.includes(customer.status) : false

  return (
    <div className="page narrow">
      <p>
        <Link to="/customers" className="muted">
          ← 顧客一覧
        </Link>
      </p>
      {(error || deleteError) && <p className="alert alert-error">{error ?? deleteError}</p>}
      {notice && <p className="alert alert-success">{notice}</p>}
      {customer && (
        <>
          <header className="page-header">
            <div>
              <h1>
                {customer.name} <CustomerStatusBadge status={customer.status} />
              </h1>
              <p className="muted">{customer.name_kana}</p>
            </div>
            <div className="actions">
              <Link to={`/customers/${customer.id}/edit`} className="btn">
                編集
              </Link>
              {/* 成約済みの顧客は削除できない(サーバー側でも禁止している) */}
              {customer.status !== 'contracted' && (
                <button type="button" className="btn btn-danger" onClick={handleDelete}>
                  削除
                </button>
              )}
            </div>
          </header>

          <section className="card status-card">
            <CustomerStatusChanger customer={customer} onChanged={handleStatusChanged} />
          </section>

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

          {/* 成約・失注の顧客には内見予定を追加できないため、追加ボタンを出さない。
              内見の実施でステータスが自動で変わることがあるため、操作後に顧客情報を読み直す */}
          <ViewingSection
            key={viewingsVersion}
            query={{ customer_id: customer.id }}
            addLink={isClosed ? undefined : `/viewings/new?customer_id=${customer.id}`}
            onChange={reload}
            hideCustomer
          />
        </>
      )}
    </div>
  )
}
