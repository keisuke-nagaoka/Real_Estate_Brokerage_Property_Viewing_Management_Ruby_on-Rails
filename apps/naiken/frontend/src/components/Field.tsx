import type { ReactNode } from 'react'

type Props = {
  label: string
  required?: boolean
  errors?: string[]
  children: ReactNode
}

// ラベル・入力欄・Railsから返った項目ごとのエラーをまとめて表示する
export function Field({ label, required, errors = [], children }: Props) {
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
