import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { Field } from './Field'

describe('Field', () => {
  it('ラベルと入力欄を関連付け、Railsから返ったエラーを表示する', () => {
    render(
      <Field label="氏名" required errors={['氏名を入力してください']}>
        <input />
      </Field>,
    )

    const input = screen.getByRole('textbox', { name: /氏名/ })
    expect(input.closest('label')).toHaveClass('has-error')
    expect(screen.getByText('必須')).toBeInTheDocument()
    expect(screen.getByText('氏名を入力してください')).toBeInTheDocument()
  })

  it('エラーがない場合はエラー表示をしない', () => {
    render(
      <Field label="メモ">
        <textarea />
      </Field>,
    )

    expect(screen.getByRole('textbox', { name: 'メモ' }).closest('label')).not.toHaveClass('has-error')
    expect(screen.queryByText('必須')).not.toBeInTheDocument()
  })
})
