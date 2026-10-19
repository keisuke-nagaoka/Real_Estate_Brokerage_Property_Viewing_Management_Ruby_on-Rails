import { useEffect, useState } from 'react'
import { apiGet } from './lib/api'

type Health = {
  status: string
  database: string
  environment: string
  time: string
}

function App() {
  const [health, setHealth] = useState<Health | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    apiGet<Health>('/health')
      .then(setHealth)
      .catch((e: unknown) => setError(e instanceof Error ? e.message : String(e)))
  }, [])

  return (
    <main className="container">
      <h1>Naiken</h1>
      <p className="lead">不動産仲介向け 顧客・内見管理システム</p>

      <section className="card">
        <h2>System status</h2>
        {error && <p className="ng">API接続エラー: {error}</p>}
        {!error && !health && <p>確認中...</p>}
        {health && (
          <dl>
            <dt>API</dt>
            <dd className={health.status === 'ok' ? 'ok' : 'ng'}>{health.status}</dd>
            <dt>Database</dt>
            <dd className={health.database === 'ok' ? 'ok' : 'ng'}>{health.database}</dd>
            <dt>Environment</dt>
            <dd>{health.environment}</dd>
            <dt>Server time</dt>
            <dd>{new Date(health.time).toLocaleString('ja-JP')}</dd>
          </dl>
        )}
      </section>
    </main>
  )
}

export default App
