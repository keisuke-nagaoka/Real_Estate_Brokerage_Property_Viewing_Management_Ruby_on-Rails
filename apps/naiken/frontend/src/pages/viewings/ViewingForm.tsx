import { useEffect, useState, type FormEvent } from 'react'
import { agentsApi } from '../../api/agents'
import { customersApi } from '../../api/customers'
import { propertiesApi } from '../../api/properties'
import { Field } from '../../components/Field'
import { ApiError, errorMessage } from '../../lib/api'
import { addDays, toDateInput, toIso, toTimeInput } from '../../lib/datetime'
import { formatPrice } from '../../lib/format'
import type { Agent, Customer, Property, Viewing, ViewingInput } from '../../types'

type FormState = {
  customer_id: number | ''
  property_id: number | ''
  agent_id: number | ''
  date: string
  start_time: string
  end_time: string
  note: string
}

type Props = {
  initial?: Viewing
  defaults?: { customer_id?: number; property_id?: number }
  submitLabel: string
  onSubmit: (input: ViewingInput) => Promise<void>
  onCancel: () => void
}

function toFormState(viewing?: Viewing, defaults: Props['defaults'] = {}): FormState {
  if (viewing) {
    return {
      customer_id: viewing.customer.id,
      property_id: viewing.property.id,
      agent_id: viewing.agent.id,
      date: toDateInput(viewing.starts_at),
      start_time: toTimeInput(viewing.starts_at),
      end_time: toTimeInput(viewing.ends_at),
      note: viewing.note ?? '',
    }
  }
  return {
    customer_id: defaults.customer_id ?? '',
    property_id: defaults.property_id ?? '',
    agent_id: '',
    date: toDateInput(addDays(new Date(), 1)),
    start_time: '10:00',
    end_time: '11:00',
    note: '',
  }
}

export function ViewingForm({ initial, defaults, submitLabel, onSubmit, onCancel }: Props) {
  const [form, setForm] = useState<FormState>(() => toFormState(initial, defaults))
  const [customers, setCustomers] = useState<Customer[]>([])
  const [properties, setProperties] = useState<Property[]>([])
  const [agents, setAgents] = useState<Agent[]>([])
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({})
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    // 小規模な運用を想定し、選択肢は上限100件までまとめて取得する
    Promise.all([customersApi.list({ per_page: 100 }), propertiesApi.list({ status: 'available', per_page: 100 }), agentsApi.list()])
      .then(([customerRes, propertyRes, agentRes]) => {
        setCustomers(customerRes.data)
        setProperties(propertyRes.data)
        setAgents(agentRes.data)
        // 顧客が指定済みで担当者が未選択なら、顧客の担当者を初期値にする
        setForm((prev) => {
          if (prev.agent_id !== '') return prev
          const customer = customerRes.data.find((c) => c.id === prev.customer_id)
          return customer ? { ...prev, agent_id: customer.agent.id } : prev
        })
      })
      .catch((e: unknown) => setError(errorMessage(e)))
  }, [])

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => setForm((prev) => ({ ...prev, [key]: value }))

  const handleCustomerChange = (value: string) => {
    const customerId = value ? Number(value) : ''
    const customer = customers.find((c) => c.id === customerId)
    setForm((prev) => ({ ...prev, customer_id: customerId, agent_id: customer ? customer.agent.id : prev.agent_id }))
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    setFieldErrors({})
    try {
      await onSubmit({
        customer_id: form.customer_id,
        property_id: form.property_id,
        agent_id: form.agent_id,
        starts_at: toIso(form.date, form.start_time),
        ends_at: toIso(form.date, form.end_time),
        note: form.note,
      })
    } catch (err) {
      // 422の場合はRailsのバリデーションエラーを項目ごとに表示する(業務ルール違反は base で返る)
      if (err instanceof ApiError && err.code === 'validation_failed') {
        setFieldErrors(err.details)
        setError(err.details.base?.join(' / ') ?? '入力内容を確認してください')
      } else {
        setError(errorMessage(err))
      }
    } finally {
      setSubmitting(false)
    }
  }

  const errorsFor = (...keys: string[]) => keys.flatMap((key) => fieldErrors[key] ?? [])

  // 編集時、掲載終了になった物件も選択肢に残す
  const propertyOptions =
    initial && !properties.some((p) => p.id === initial.property.id)
      ? [{ id: initial.property.id, name: `${initial.property.name}（掲載終了）`, price: null }, ...properties]
      : properties

  return (
    <form className="card form" onSubmit={handleSubmit} noValidate>
      {error && <p className="alert alert-error">{error}</p>}

      <div className="form-row">
        <Field label="顧客" required errors={errorsFor('customer', 'customer_id')}>
          <select className="input" value={form.customer_id} onChange={(e) => handleCustomerChange(e.target.value)}>
            <option value="">選択してください</option>
            {customers.map((customer) => (
              <option key={customer.id} value={customer.id}>
                {customer.name}（{customer.name_kana}）
              </option>
            ))}
          </select>
        </Field>
        <Field label="担当者" required errors={errorsFor('agent', 'agent_id')}>
          <select className="input" value={form.agent_id} onChange={(e) => set('agent_id', e.target.value ? Number(e.target.value) : '')}>
            <option value="">選択してください</option>
            {agents.map((agent) => (
              <option key={agent.id} value={agent.id}>
                {agent.name}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <Field label="物件（掲載中のみ）" required errors={errorsFor('property', 'property_id')}>
        <select className="input" value={form.property_id} onChange={(e) => set('property_id', e.target.value ? Number(e.target.value) : '')}>
          <option value="">選択してください</option>
          {propertyOptions.map((property) => (
            <option key={property.id} value={property.id}>
              {property.name}
              {property.price !== null && ` ／ ${formatPrice(property.price)}`}
            </option>
          ))}
        </select>
      </Field>

      <div className="form-row three">
        <Field label="日付" required errors={errorsFor('starts_at')}>
          <input type="date" className="input" value={form.date} onChange={(e) => set('date', e.target.value)} />
        </Field>
        <Field label="開始時刻" required>
          <input type="time" className="input" step={900} value={form.start_time} onChange={(e) => set('start_time', e.target.value)} />
        </Field>
        <Field label="終了時刻" required errors={errorsFor('ends_at')}>
          <input type="time" className="input" step={900} value={form.end_time} onChange={(e) => set('end_time', e.target.value)} />
        </Field>
      </div>

      <Field label="メモ" errors={errorsFor('note')}>
        <textarea className="input" rows={3} value={form.note} onChange={(e) => set('note', e.target.value)} placeholder="確認したい点、持ち物など" />
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
