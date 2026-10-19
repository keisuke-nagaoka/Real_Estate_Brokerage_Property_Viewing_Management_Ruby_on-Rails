import { useState } from 'react'
import type { PropertyPhoto } from '../types'

type Props = {
  photos: PropertyPhoto[]
  alt: string
}

// 大きい写真1枚と、切り替え用のサムネイルの一覧
export function PhotoGallery({ photos, alt }: Props) {
  const [selectedId, setSelectedId] = useState<number | null>(null)
  // 選択中の写真が削除された場合は1枚目を表示する
  const selected = photos.find((photo) => photo.id === selectedId) ?? photos[0]

  if (!selected) {
    return <div className="gallery-empty">写真はまだ登録されていません</div>
  }

  return (
    <div className="gallery">
      <img className="gallery-main" src={selected.url} alt={`${alt}の写真（${selected.filename}）`} />
      {photos.length > 1 && (
        <div className="gallery-thumbs">
          {photos.map((photo, i) => (
            <button
              key={photo.id}
              type="button"
              className={`gallery-thumb${photo.id === selected.id ? ' active' : ''}`}
              onClick={() => setSelectedId(photo.id)}
              aria-label={`${i + 1}枚目の写真を表示`}
            >
              <img src={photo.thumbnail_url} alt="" />
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
