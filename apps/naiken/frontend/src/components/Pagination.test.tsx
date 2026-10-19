import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { Pagination } from './Pagination'

describe('Pagination', () => {
  it('1ページしかない場合は表示しない', () => {
    const { container } = render(<Pagination meta={{ page: 1, per_page: 20, total_count: 5, total_pages: 1 }} onChange={vi.fn()} />)

    expect(container).toBeEmptyDOMElement()
  })

  it('最初のページでは「前へ」を押せず、「次へ」で次のページ番号を渡す', async () => {
    const onChange = vi.fn()
    render(<Pagination meta={{ page: 1, per_page: 20, total_count: 45, total_pages: 3 }} onChange={onChange} />)

    expect(screen.getByText('1 / 3 ページ（全45件）')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: '前へ' })).toBeDisabled()

    await userEvent.click(screen.getByRole('button', { name: '次へ' }))
    expect(onChange).toHaveBeenCalledWith(2)
  })
})
