import { useState, type FormEvent } from 'react'
import { Field } from '../../components/Field'
import { ApiError, errorMessage } from '../../lib/api'
import { propertyStatusLabels } from '../../lib/labels'
import type { Property, PropertyInput, PropertyStatus } from '../../types'

type Props = {
  initial?: Property
  submitLabel: string
  onSubmit: (input: PropertyInput) => Promise<void>
  onCancel: () => void
}

function toInput(property?: Property): PropertyInput {
  return {
    name: property?.name ?? '',
    address: property?.address ?? '',
    price: property?.price ?? '',
    layout: property?.layout ?? '',
    floor_area: property?.floor_area ?? '',
    built_year: property?.built_year ?? '',
    nearest_station: property?.nearest_station ?? '',
    walk_minutes: property?.walk_minutes ?? '',
    status: property?.status ?? 'available',
    note: property?.note ?? '',
  }
}

const toNumber = (value: string): number | '' => (value === '' ? '' : Number(value))

export function PropertyForm({ initial, submitLabel, onSubmit, onCancel }: Props) {
  const [input, setInput] = useState<PropertyInput>(() => toInput(initial))
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({})
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const set = <K extends keyof PropertyInput>(key: K, value: PropertyInput[K]) => setInput((prev) => ({ ...prev, [key]: value }))

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    setFieldErrors({})
    try {
      await onSubmit(input)
    } catch (err) {
      // 422の場合はRailsのバリデーションエラーを項目ごとに表示する
      if (err instanceof ApiError && err.code === 'validation_failed') {
        setFieldErrors(err.details)
        setError('入力内容を確認してください')
      } else {
        setError(errorMessage(err))
      }
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form className="card form" onSubmit={handleSubmit} noValidate>
      {error && <p className="alert alert-error">{error}</p>}

      <Field label="物件名" required errors={fieldErrors.name}>
        <input className="input" value={input.name} onChange={(e) => set('name', e.target.value)} placeholder="パークハウス世田谷桜丘" />
      </Field>

      <Field label="住所" required errors={fieldErrors.address}>
        <input className="input" value={input.address} onChange={(e) => set('address', e.target.value)} placeholder="東京都世田谷区桜丘3丁目" />
      </Field>

      <div className="form-row">
        <Field label="価格（万円）" required errors={fieldErrors.price}>
          <input type="number" className="input" min={1} value={input.price} onChange={(e) => set('price', toNumber(e.target.value))} />
        </Field>
        <Field label="掲載状況" required errors={fieldErrors.status}>
          <select className="input" value={input.status} onChange={(e) => set('status', e.target.value as PropertyStatus)}>
            {Object.entries(propertyStatusLabels).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <div className="form-row three">
        <Field label="間取り" errors={fieldErrors.layout}>
          <input className="input" value={input.layout} onChange={(e) => set('layout', e.target.value)} placeholder="3LDK" />
        </Field>
        <Field label="専有面積（㎡）" errors={fieldErrors.floor_area}>
          <input type="number" className="input" min={0} step={0.01} value={input.floor_area} onChange={(e) => set('floor_area', toNumber(e.target.value))} />
        </Field>
        <Field label="築年（西暦）" errors={fieldErrors.built_year}>
          <input type="number" className="input" min={1900} value={input.built_year} onChange={(e) => set('built_year', toNumber(e.target.value))} placeholder="2015" />
        </Field>
      </div>

      <div className="form-row">
        <Field label="最寄り駅" errors={fieldErrors.nearest_station}>
          <input className="input" value={input.nearest_station} onChange={(e) => set('nearest_station', e.target.value)} placeholder="千歳船橋" />
        </Field>
        <Field label="駅徒歩（分）" errors={fieldErrors.walk_minutes}>
          <input type="number" className="input" min={0} value={input.walk_minutes} onChange={(e) => set('walk_minutes', toNumber(e.target.value))} />
        </Field>
      </div>

      <Field label="メモ" errors={fieldErrors.note}>
        <textarea className="input" rows={4} value={input.note} onChange={(e) => set('note', e.target.value)} />
      </Field>

      <div className="form-actions">
        <button type="button" className="btn" onClick={onCancel}>
          キャンセル
        </button>
        <button type="submit" className="btn btn-primary" disabled={submitting}>
          {submitting ? '保存中...' : submitLabel}
        </button>
      </div>
    </form>
  )
}
