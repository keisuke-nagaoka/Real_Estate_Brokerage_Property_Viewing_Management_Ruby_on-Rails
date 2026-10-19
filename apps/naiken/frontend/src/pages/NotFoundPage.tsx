import { Link } from 'react-router'

export function NotFoundPage() {
  return (
    <div className="page">
      <h1>ページが見つかりません</h1>
      <Link to="/customers">顧客一覧へ戻る</Link>
    </div>
  )
}
