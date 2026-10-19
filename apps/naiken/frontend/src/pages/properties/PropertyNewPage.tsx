import { useNavigate } from 'react-router'
import { propertiesApi } from '../../api/properties'
import { PropertyForm } from './PropertyForm'

export function PropertyNewPage() {
  const navigate = useNavigate()

  return (
    <div className="page narrow">
      <header className="page-header">
        <h1>物件を登録</h1>
      </header>
      <PropertyForm
        submitLabel="登録する"
        onSubmit={async (input) => {
          const res = await propertiesApi.create(input)
          navigate(`/properties/${res.data.id}`)
        }}
        onCancel={() => navigate('/properties')}
      />
    </div>
  )
}
