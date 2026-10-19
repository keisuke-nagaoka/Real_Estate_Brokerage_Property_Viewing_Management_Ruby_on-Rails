import { useEffect, useState, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router'
import { propertiesApi } from '../../api/properties'
import { Pagination } from '../../components/Pagination'
import { errorMessage } from '../../lib/api'
import { formatAccess, formatBuildingAge, formatPrice } from '../../lib/format'
import { propertyStatusLabels } from '../../lib/labels'
import type { PageMeta, Property, PropertyArea } from '../../types'

type ListResult = {
  key: string
  properties: Property[]
  meta: PageMeta | null
  error: string | null
}

export function PropertyListPage() {
  // 検索条件はURLのクエリに持たせ、リロードやブラウザバックでも条件を保持する
  const [searchParams, setSearchParams] = useSearchParams()
  const q = searchParams.get('q') ?? ''
  const prefecture = searchParams.get('prefecture') ?? ''
  const city = searchParams.get('city') ?? ''
  const status = searchParams.get('status') ?? ''
  const priceMin = searchParams.get('price_min') ?? ''
  const priceMax = searchParams.get('price_max') ?? ''
  const page = Number(searchParams.get('page') ?? 1)
  const queryKey = `${q}|${prefecture}|${city}|${status}|${priceMin}|${priceMax}|${page}`

  // 絞り込みの選択肢は、物件があるエリアだけをAPIから取得する
  const [areas, setAreas] = useState<PropertyArea[]>([])
  const cities = areas.find((area) => area.prefecture === prefecture)?.cities ?? []

  useEffect(() => {
    propertiesApi.areas().then((res) => setAreas(res.data))
  }, [])

  // 取得結果は「どの検索条件の結果か(key)」と一緒に保持し、条件と一致しない間を読み込み中とみなす
  const [result, setResult] = useState<ListResult | null>(null)
  const loading = result?.key !== queryKey
  const properties = result?.properties ?? []

  useEffect(() => {
    let ignore = false
    propertiesApi
      .list({ q, prefecture, city, status, price_min: priceMin, price_max: priceMax, page })
      .then((res) => !ignore && setResult({ key: queryKey, properties: res.data, meta: res.meta, error: null }))
      .catch((e: unknown) => !ignore && setResult({ key: queryKey, properties: [], meta: null, error: errorMessage(e) }))
    return () => {
      ignore = true
    }
  }, [q, prefecture, city, status, priceMin, priceMax, page, queryKey])

  const updateQuery = (next: Record<string, string>) => {
    const params = new URLSearchParams(searchParams)
    for (const [key, value] of Object.entries(next)) {
      if (value) params.set(key, value)
      else params.delete(key)
    }
    setSearchParams(params)
  }

  const handleSearch = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const form = new FormData(e.currentTarget)
    const value = (name: string) => String(form.get(name) ?? '').trim()
    updateQuery({ q: value('q'), price_min: value('price_min'), price_max: value('price_max'), page: '' })
  }

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>物件</h1>
          <p className="muted">顧客に紹介する物件の管理</p>
        </div>
        <Link to="/properties/new" className="btn btn-primary">
          ＋ 物件を登録
        </Link>
      </header>

      {/* key に検索条件を渡し、ブラウザバック等でURLの条件が変わったら入力欄も作り直す */}
      <form className="toolbar" onSubmit={handleSearch} key={`${q}|${priceMin}|${priceMax}`}>
        <input type="search" name="q" className="input" placeholder="物件名・住所・最寄り駅で検索" defaultValue={q} />
        <div className="range">
          <input type="number" name="price_min" className="input" placeholder="下限" min={0} defaultValue={priceMin} aria-label="価格の下限(万円)" />
          <span>〜</span>
          <input type="number" name="price_max" className="input" placeholder="上限" min={0} defaultValue={priceMax} aria-label="価格の上限(万円)" />
          <span className="muted">万円</span>
        </div>
        <button type="submit" className="btn">
          検索
        </button>
      </form>

      <div className="toolbar">
        <select
          className="input select-area"
          value={prefecture}
          onChange={(e) => updateQuery({ prefecture: e.target.value, city: '', page: '' })}
          aria-label="都道府県"
        >
          <option value="">すべての都道府県</option>
          {areas.map((area) => (
            <option key={area.prefecture} value={area.prefecture}>
              {area.prefecture}（{area.count}）
            </option>
          ))}
        </select>
        <select
          className="input select-area"
          value={city}
          disabled={!prefecture}
          onChange={(e) => updateQuery({ city: e.target.value, page: '' })}
          aria-label="市区町村"
        >
          <option value="">{prefecture ? 'すべての市区町村' : '市区町村（都道府県を選択）'}</option>
          {cities.map((c) => (
            <option key={c.name} value={c.name}>
              {c.name}（{c.count}）
            </option>
          ))}
        </select>
        <div className="segmented">
          {[
            { value: '', label: 'すべて' },
            { value: 'available', label: propertyStatusLabels.available },
            { value: 'closed', label: propertyStatusLabels.closed },
          ].map((option) => (
            <button
              key={option.value}
              type="button"
              className={status === option.value ? 'active' : undefined}
              onClick={() => updateQuery({ status: option.value, page: '' })}
            >
              {option.label}
            </button>
          ))}
        </div>
      </div>

      {result?.error && <p className="alert alert-error">{result.error}</p>}

      <div className={`property-grid${loading ? ' loading' : ''}`}>
        {properties.map((property) => (
          <Link key={property.id} to={`/properties/${property.id}`} className={`property-card${property.status === 'closed' ? ' is-closed' : ''}`}>
            <div className="property-cover">
              {property.photos[0] ? (
                <img src={property.photos[0].thumbnail_url} alt={`${property.name}の外観`} loading="lazy" />
              ) : (
                <span className="property-cover-empty">No Photo</span>
              )}
              <span className="property-cover-price">{formatPrice(property.price)}</span>
              <span className={`badge badge-${property.status} property-cover-badge`}>{propertyStatusLabels[property.status]}</span>
              {property.photos.length > 1 && <span className="property-cover-count">📷 {property.photos.length}</span>}
            </div>
            <div className="property-name">{property.name}</div>
            <div className="muted small">{property.address}</div>
            <div className="property-specs">
              <span>{property.layout ?? '-'}</span>
              <span>{property.floor_area !== null ? `${property.floor_area}㎡` : '-'}</span>
              <span>{formatBuildingAge(property.built_year)}</span>
            </div>
            <div className="small">{formatAccess(property.nearest_station, property.walk_minutes)}</div>
          </Link>
        ))}
      </div>
      {!loading && properties.length === 0 && !result?.error && <p className="card empty">該当する物件はありません</p>}

      {result?.meta && <Pagination meta={result.meta} onChange={(next) => updateQuery({ page: String(next) })} />}
    </div>
  )
}
