// APIは同一オリジンの /naiken/api/ 配下(nginxがRailsへ転送)にあるためCORS設定は不要
const API_BASE = `${import.meta.env.BASE_URL}api/v1`

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Accept: 'application/json' },
  })
  if (!res.ok) {
    throw new Error(`API error: ${res.status} ${res.statusText}`)
  }
  return res.json() as Promise<T>
}
