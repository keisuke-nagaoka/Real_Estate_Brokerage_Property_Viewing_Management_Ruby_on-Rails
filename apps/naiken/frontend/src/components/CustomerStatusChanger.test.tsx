import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { customersApi } from '../api/customers'
import { ApiError } from '../lib/api'
import type { Customer } from '../types'
import { CustomerStatusChanger } from './CustomerStatusChanger'

vi.mock('../api/customers', () => ({ customersApi: { changeStatus: vi.fn() } }))

function buildCustomer(overrides: Partial<Customer> = {}): Customer {
  return {
    id: 1,
    name: '山田 太郎',
    name_kana: 'ヤマダ タロウ',
    status: 'viewing_scheduled',
    next_statuses: ['considering', 'contracted', 'lost'],
    email: null,
    phone: null,
    budget_max: null,
    desired_area: null,
    note: null,
    agent: { id: 1, name: '佐藤 健太', email: 'sato@example.com' },
    created_at: '2026-10-19T10:00:00+09:00',
    updated_at: '2026-10-19T10:00:00+09:00',
    ...overrides,
  }
}

describe('CustomerStatusChanger', () => {
  beforeEach(() => {
    vi.mocked(customersApi.changeStatus).mockReset()
  })

  it('APIが返した「変更できるステータス」だけをボタンで表示する', () => {
    render(<CustomerStatusChanger customer={buildCustomer()} onChanged={vi.fn()} />)

    expect(screen.getAllByRole('button').map((b) => b.textContent)).toEqual(['検討中', '成約', '失注'])
  })

  it('成約済みの場合は変更できない旨を表示する', () => {
    render(<CustomerStatusChanger customer={buildCustomer({ status: 'contracted', next_statuses: [] })} onChanged={vi.fn()} />)

    expect(screen.queryByRole('button')).not.toBeInTheDocument()
    expect(screen.getByText('成約済みのため、ステータスは変更できません')).toBeInTheDocument()
  })

  it('確認後にステータスを変更し、キャンセルした内見予定の件数を親に渡す', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const updated = buildCustomer({ status: 'contracted', next_statuses: [] })
    vi.mocked(customersApi.changeStatus).mockResolvedValue({ data: updated, meta: { canceled_viewings_count: 2 } })
    const onChanged = vi.fn()

    render(<CustomerStatusChanger customer={buildCustomer()} onChanged={onChanged} />)
    await userEvent.click(screen.getByRole('button', { name: '成約' }))

    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('予定中の内見予定はすべてキャンセルされます'))
    expect(customersApi.changeStatus).toHaveBeenCalledWith(1, 'contracted')
    expect(onChanged).toHaveBeenCalledWith(updated, 2)
  })

  it('確認ダイアログでキャンセルした場合はAPIを呼ばない', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)

    render(<CustomerStatusChanger customer={buildCustomer()} onChanged={vi.fn()} />)
    await userEvent.click(screen.getByRole('button', { name: '検討中' }))

    expect(customersApi.changeStatus).not.toHaveBeenCalled()
  })

  it('APIがエラーを返した場合はメッセージを表示する', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    vi.mocked(customersApi.changeStatus).mockRejectedValue(
      new ApiError(422, { code: 'validation_failed', message: '対応ステータスを「内見予定」から「検討中」に変更することはできません' }),
    )

    render(<CustomerStatusChanger customer={buildCustomer()} onChanged={vi.fn()} />)
    await userEvent.click(screen.getByRole('button', { name: '検討中' }))

    expect(await screen.findByText('対応ステータスを「内見予定」から「検討中」に変更することはできません')).toBeInTheDocument()
  })
})
