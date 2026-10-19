import { useNavigate, useParams } from 'react-router'
import { customersApi } from '../../api/customers'
import { NotFoundPage } from '../NotFoundPage'
import { CustomerForm } from './CustomerForm'
import { useCustomer } from './useCustomer'

export function CustomerEditPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { customer, error, notFound } = useCustomer(id)

  if (notFound) return <NotFoundPage />

  return (
    <div className="page narrow">
      <header className="page-header">
        <h1>顧客情報を編集</h1>
      </header>
      {error && <p className="alert alert-error">{error}</p>}
      {customer && (
        <CustomerForm
          initial={customer}
          submitLabel="更新する"
          onSubmit={async (input) => {
            await customersApi.update(customer.id, input)
            navigate(`/customers/${customer.id}`)
          }}
          onCancel={() => navigate(`/customers/${customer.id}`)}
        />
      )}
    </div>
  )
}
