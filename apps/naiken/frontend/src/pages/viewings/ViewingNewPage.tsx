import { useNavigate, useSearchParams } from 'react-router'
import { viewingsApi } from '../../api/viewings'
import { ViewingForm } from './ViewingForm'

export function ViewingNewPage() {
  const navigate = useNavigate()
  // 顧客・物件の詳細画面から来た場合は、その顧客・物件を初期選択にする
  const [searchParams] = useSearchParams()
  const toId = (key: string) => (searchParams.get(key) ? Number(searchParams.get(key)) : undefined)
  const defaults = { customer_id: toId('customer_id'), property_id: toId('property_id') }
  const backTo = defaults.customer_id ? `/customers/${defaults.customer_id}` : defaults.property_id ? `/properties/${defaults.property_id}` : '/viewings'

  return (
    <div className="page narrow">
      <header className="page-header">
        <h1>内見予定を登録</h1>
      </header>
      <ViewingForm
        defaults={defaults}
        submitLabel="登録する"
        onSubmit={async (input) => {
          await viewingsApi.create(input)
          navigate(backTo)
        }}
        onCancel={() => navigate(backTo)}
      />
    </div>
  )
}
