import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import { propertiesApi } from '../../api/properties'
import { ViewingSection } from '../../components/ViewingSection'
import { errorMessage } from '../../lib/api'
import { formatAccess, formatBuildingAge, formatDateTime, formatPrice } from '../../lib/format'
import { propertyStatusLabels } from '../../lib/labels'
import { NotFoundPage } from '../NotFoundPage'
import { useProperty } from './useProperty'

export function PropertyDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { property, error, notFound } = useProperty(id)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  if (notFound) return <NotFoundPage />

  const handleDelete = async () => {
    if (!property || !window.confirm(`「${property.name}」を削除しますか？この操作は取り消せません。`)) return
    try {
      await propertiesApi.delete(property.id)
      navigate('/properties')
    } catch (e) {
      setDeleteError(errorMessage(e))
    }
  }

  return (
    <div className="page narrow">
      <p>
        <Link to="/properties" className="muted">
          ← 物件一覧
        </Link>
      </p>
      {(error || deleteError) && <p className="alert alert-error">{error ?? deleteError}</p>}
      {property && (
        <>
          <header className="page-header">
            <div>
              <h1>
                {property.name} <span className={`badge badge-${property.status}`}>{propertyStatusLabels[property.status]}</span>
              </h1>
              <p className="muted">{property.address}</p>
            </div>
            <div className="actions">
              <Link to={`/properties/${property.id}/edit`} className="btn">
                編集
              </Link>
              <button type="button" className="btn btn-danger" onClick={handleDelete}>
                削除
              </button>
            </div>
          </header>

          <section className="card">
            <dl className="detail">
              <dt>価格</dt>
              <dd className="property-price">{formatPrice(property.price)}</dd>
              <dt>間取り</dt>
              <dd>{property.layout ?? '-'}</dd>
              <dt>専有面積</dt>
              <dd>{property.floor_area !== null ? `${property.floor_area}㎡` : '-'}</dd>
              <dt>築年</dt>
              <dd>{property.built_year !== null ? `${property.built_year}年（${formatBuildingAge(property.built_year)}）` : '-'}</dd>
              <dt>交通</dt>
              <dd>{formatAccess(property.nearest_station, property.walk_minutes)}</dd>
              <dt>メモ</dt>
              <dd className="pre-wrap">{property.note ?? '-'}</dd>
              <dt>登録日時</dt>
              <dd>{formatDateTime(property.created_at)}</dd>
              <dt>更新日時</dt>
              <dd>{formatDateTime(property.updated_at)}</dd>
            </dl>
          </section>

          {/* 掲載終了の物件には内見予定を追加できないため、追加ボタンを出さない */}
          <ViewingSection
            query={{ property_id: property.id }}
            addLink={property.status === 'available' ? `/viewings/new?property_id=${property.id}` : undefined}
            hideProperty
          />
        </>
      )}
    </div>
  )
}
