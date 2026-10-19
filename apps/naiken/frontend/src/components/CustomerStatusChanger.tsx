import { useState } from 'react'
import { customersApi } from '../api/customers'
import { errorMessage } from '../lib/api'
import { closedCustomerStatuses, customerStatusLabels } from '../lib/labels'
import type { Customer, CustomerStatus } from '../types'

type Props = {
  customer: Customer
  onChanged: (customer: Customer, canceledViewingsCount: number) => void
}

// 遷移ルール上、今のステータスから変更できる先だけをボタンで表示する(ルールの判定はサーバー側で行う)
export function CustomerStatusChanger({ customer, onChanged }: Props) {
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  if (customer.next_statuses.length === 0) {
    return <p className="muted small">成約済みのため、ステータスは変更できません</p>
  }

  const change = async (status: CustomerStatus) => {
    const label = customerStatusLabels[status]
    const message = closedCustomerStatuses.includes(status)
      ? `ステータスを「${label}」に変更しますか？\n予定中の内見予定はすべてキャンセルされます。${status === 'contracted' ? '\n成約後はステータスを変更できません。' : ''}`
      : `ステータスを「${label}」に変更しますか？`
    if (!window.confirm(message)) return

    setBusy(true)
    setError(null)
    try {
      const res = await customersApi.changeStatus(customer.id, status)
      onChanged(res.data, res.meta.canceled_viewings_count)
    } catch (e) {
      setError(errorMessage(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="status-changer">
      <span className="muted small">ステータスを変更:</span>
      {customer.next_statuses.map((status) => (
        <button key={status} type="button" className={`btn btn-small btn-cs-${status}`} disabled={busy} onClick={() => change(status)}>
          {customerStatusLabels[status]}
        </button>
      ))}
      {error && <p className="alert alert-error">{error}</p>}
    </div>
  )
}
