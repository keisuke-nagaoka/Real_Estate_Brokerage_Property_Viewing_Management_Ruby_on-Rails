import { describe, expect, it, vi } from 'vitest'
import { api, ApiError } from './api'

function mockFetch(status: number, body?: unknown) {
  const response = new Response(body === undefined ? null : typeof body === 'string' ? body : JSON.stringify(body), { status })
  return vi.spyOn(globalThis, 'fetch').mockResolvedValue(response)
}

describe('api', () => {
  it('配信パス(本番では /naiken/)配下の api/v1 にリクエストし、空の検索条件はクエリに含めない', async () => {
    const fetch = mockFetch(200, { data: [] })

    await api.get('/customers', { q: '山田', agent_id: '', page: 2, status: undefined })

    expect(fetch).toHaveBeenCalledWith(
      `${import.meta.env.BASE_URL}api/v1/customers?q=%E5%B1%B1%E7%94%B0&page=2`,
      expect.objectContaining({ method: 'GET' }),
    )
  })

  it('送信するデータはJSONにする', async () => {
    const fetch = mockFetch(201, { data: { id: 1 } })

    const res = await api.post<{ data: { id: number } }>('/customers', { customer: { name: '山田' } })

    expect(res.data.id).toBe(1)
    const [, init] = fetch.mock.calls[0]
    expect(init?.body).toBe(JSON.stringify({ customer: { name: '山田' } }))
    expect(init?.headers).toMatchObject({ 'Content-Type': 'application/json' })
  })

  it('204の場合は本文を読まずに undefined を返す', async () => {
    mockFetch(204)

    await expect(api.delete('/customers/1')).resolves.toBeUndefined()
  })

  it('422の場合はRailsのエラー内容を持った ApiError を投げる', async () => {
    mockFetch(422, { error: { code: 'validation_failed', message: '氏名を入力してください', details: { name: ['氏名を入力してください'] } } })

    const error = await api.post('/customers', {}).catch((e: unknown) => e)

    expect(error).toBeInstanceOf(ApiError)
    expect(error).toMatchObject({ status: 422, code: 'validation_failed', message: '氏名を入力してください', details: { name: ['氏名を入力してください'] } })
  })

  it('JSON以外のエラー(nginxの502など)でも ApiError にする', async () => {
    mockFetch(502, '<html>Bad Gateway</html>')

    await expect(api.get('/customers')).rejects.toMatchObject({ status: 502, code: 'unknown', message: '通信エラーが発生しました (502)' })
  })
})
