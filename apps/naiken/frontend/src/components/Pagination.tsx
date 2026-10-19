import type { PageMeta } from '../types'

type Props = {
  meta: PageMeta
  onChange: (page: number) => void
}

export function Pagination({ meta, onChange }: Props) {
  if (meta.total_pages <= 1) return null

  return (
    <div className="pagination">
      <button type="button" className="btn" disabled={meta.page <= 1} onClick={() => onChange(meta.page - 1)}>
        前へ
      </button>
      <span>
        {meta.page} / {meta.total_pages} ページ（全{meta.total_count}件）
      </span>
      <button type="button" className="btn" disabled={meta.page >= meta.total_pages} onClick={() => onChange(meta.page + 1)}>
        次へ
      </button>
    </div>
  )
}
