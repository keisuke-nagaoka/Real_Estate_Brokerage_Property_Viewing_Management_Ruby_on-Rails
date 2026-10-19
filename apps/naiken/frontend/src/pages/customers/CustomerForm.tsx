import { useEffect, useState, type FormEvent, type ReactNode } from 'react'
import { agentsApi } from '../../api/agents'
import { ApiError, errorMessage } from '../../lib/api'
import type { Agent, Customer, CustomerInput } from '../../types'

type Props = {
  initial?: Customer
  submitLabel: string
  onSubmit: (input: CustomerInput) => Promise<void>
  onCancel: () => void
}

function toInput(customer?: Customer): CustomerInput {
  return {
    agent_id: customer?.agent.id ?? '',
    name: customer?.name ?? '',
    name_kana: customer?.name_kana ?? '',
    email: customer?.email ?? '',
    phone: customer?.phone ?? '',
    budget_max: customer?.budget_max ?? '',
    desired_area: customer?.desired_area ?? '',
    note: customer?.note ?? '',
  }
}

export function CustomerForm({ initial, submitLabel, onSubmit, onCancel }: Props) {
  const [input, setInput] = useState<CustomerInput>(() => toInput(initial))
  const [agents, setAgents] = useState<Agent[]>([])
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({})
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    agentsApi.list().then((res) => setAgents(res.data)).catch((e: unknown) => setError(errorMessage(e)))
  }, [])

  const set = <K extends keyof CustomerInput>(key: K, value: CustomerInput[K]) => setInput((prev) => ({ ...prev, [key]: value }))

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

  // agent(belongs_to)のエラーは agent キーで返るため、担当者欄に表示する
  const errorsFor = (...keys: string[]) => keys.flatMap((key) => fieldErrors[key] ?? [])

  return (
    <form className="card form" onSubmit={handleSubmit} noValidate>
      {error && <p className="alert alert-error">{error}</p>}

      <Field label="担当者" required errors={errorsFor('agent', 'agent_id')}>
        <select className="input" value={input.agent_id} onChange={(e) => set('agent_id', e.target.value ? Number(e.target.value) : '')}>
          <option value="">選択してください</option>
          {agents.map((agent) => (
            <option key={agent.id} value={agent.id}>
              {agent.name}
            </option>
          ))}
        </select>
      </Field>

      <div className="form-row">
        <Field label="氏名" required errors={errorsFor('name')}>
          <input className="input" value={input.name} onChange={(e) => set('name', e.target.value)} placeholder="山田 太郎" />
        </Field>
        <Field label="フリガナ" required errors={errorsFor('name_kana')}>
          <input className="input" value={input.name_kana} onChange={(e) => set('name_kana', e.target.value)} placeholder="ヤマダ タロウ" />
        </Field>
      </div>

      <div className="form-row">
        <Field label="メールアドレス" errors={errorsFor('email')}>
          <input type="email" className="input" value={input.email} onChange={(e) => set('email', e.target.value)} />
        </Field>
        <Field label="電話番号" errors={errorsFor('phone')}>
          <input type="tel" className="input" value={input.phone} onChange={(e) => set('phone', e.target.value)} placeholder="090-1234-5678" />
        </Field>
      </div>

      <div className="form-row">
        <Field label="予算上限（万円）" errors={errorsFor('budget_max')}>
          <input
            type="number"
            className="input"
            min={1}
            value={input.budget_max}
            onChange={(e) => set('budget_max', e.target.value === '' ? '' : Number(e.target.value))}
          />
        </Field>
        <Field label="希望エリア" errors={errorsFor('desired_area')}>
          <input className="input" value={input.desired_area} onChange={(e) => set('desired_area', e.target.value)} placeholder="世田谷区" />
        </Field>
      </div>

      <Field label="メモ" errors={errorsFor('note')}>
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

function Field({ label, required, errors, children }: { label: string; required?: boolean; errors: string[]; children: ReactNode }) {
  return (
    <label className={`field${errors.length ? ' has-error' : ''}`}>
      <span className="field-label">
        {label}
        {required && <span className="required">必須</span>}
      </span>
      {children}
      {errors.map((message) => (
        <span key={message} className="field-error">
          {message}
        </span>
      ))}
    </label>
  )
}
