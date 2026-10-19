import { useNavigate, useParams } from 'react-router'
import { propertiesApi } from '../../api/properties'
import { NotFoundPage } from '../NotFoundPage'
import { PropertyForm } from './PropertyForm'
import { useProperty } from './useProperty'

export function PropertyEditPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { property, error, notFound } = useProperty(id)

  if (notFound) return <NotFoundPage />

  return (
    <div className="page narrow">
      <header className="page-header">
        <h1>物件情報を編集</h1>
      </header>
      {error && <p className="alert alert-error">{error}</p>}
      {property && (
        <PropertyForm
          initial={property}
          submitLabel="更新する"
          onSubmit={async (input) => {
            await propertiesApi.update(property.id, input)
            navigate(`/properties/${property.id}`)
          }}
          onCancel={() => navigate(`/properties/${property.id}`)}
        />
      )}
    </div>
  )
}
