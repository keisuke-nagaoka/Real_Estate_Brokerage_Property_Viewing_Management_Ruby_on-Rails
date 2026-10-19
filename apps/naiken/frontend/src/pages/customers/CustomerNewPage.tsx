import { useNavigate } from 'react-router'
import { customersApi } from '../../api/customers'
import { CustomerForm } from './CustomerForm'

export function CustomerNewPage() {
  const navigate = useNavigate()

  return (
    <div className="page narrow">
      <header className="page-header">
        <h1>顧客を登録</h1>
      </header>
      <CustomerForm
        submitLabel="登録する"
        onSubmit={async (input) => {
          const res = await customersApi.create(input)
          navigate(`/customers/${res.data.id}`)
        }}
        onCancel={() => navigate('/customers')}
      />
    </div>
  )
}
