// APIは同一オリジンの /naiken/api/ 配下(nginxがRailsへ転送)にあるためCORS設定は不要
const API_BASE = `${import.meta.env.BASE_URL}api/v1`

// Rails側のエラーレスポンス { error: { code, message, details } } に対応する
export type ApiErrorBody = {
  code: string
  message: string
  details?: Record<string, string[]>
}

export class ApiError extends Error {
  readonly status: number
  readonly code: string
  readonly details: Record<string, string[]>

  constructor(status: number, body: ApiErrorBody) {
    super(body.message)
    this.status = status
    this.code = body.code
    this.details = body.details ?? {}
  }
}

type Query = Record<string, string | number | undefined | null>

function buildUrl(path: string, query?: Query): string {
  const params = new URLSearchParams()
  for (const [key, value] of Object.entries(query ?? {})) {
    if (value !== undefined && value !== null && value !== '') {
      params.set(key, String(value))
    }
  }
  const qs = params.toString()
  return `${API_BASE}${path}${qs ? `?${qs}` : ''}`
}

async function request<T>(method: string, path: string, options: { query?: Query; body?: unknown } = {}): Promise<T> {
  // ファイルを送る場合(FormData)は、Content-Type をブラウザに任せて multipart/form-data で送る
  const isFormData = options.body instanceof FormData
  const res = await fetch(buildUrl(path, options.query), {
    method,
    headers: {
      Accept: 'application/json',
      ...(options.body !== undefined && !isFormData ? { 'Content-Type': 'application/json' } : {}),
    },
    body: options.body === undefined ? undefined : isFormData ? (options.body as FormData) : JSON.stringify(options.body),
  })

  if (res.status === 204) {
    return undefined as T
  }

  const json = await res.json().catch(() => null)
  if (!res.ok) {
    const body: ApiErrorBody = json?.error ?? { code: 'unknown', message: `通信エラーが発生しました (${res.status})` }
    throw new ApiError(res.status, body)
  }
  return json as T
}

export const api = {
  get: <T>(path: string, query?: Query) => request<T>('GET', path, { query }),
  post: <T>(path: string, body: unknown) => request<T>('POST', path, { body }),
  patch: <T>(path: string, body: unknown = {}) => request<T>('PATCH', path, { body }),
  delete: (path: string) => request<void>('DELETE', path),
  deleteWithResponse: <T>(path: string) => request<T>('DELETE', path),
}

export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}
