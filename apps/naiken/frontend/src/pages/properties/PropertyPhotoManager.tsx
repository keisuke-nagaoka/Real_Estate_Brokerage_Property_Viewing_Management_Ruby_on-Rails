import { useRef, useState, type ChangeEvent } from 'react'
import { propertiesApi } from '../../api/properties'
import { ApiError, errorMessage } from '../../lib/api'
import { MAX_PHOTOS, PHOTO_TYPES, validatePhotoFiles } from '../../lib/photos'
import type { Property } from '../../types'

type Props = {
  property: Property
  onChange: (property: Property) => void
}

// 物件写真の追加・削除。1枚目が一覧のカバー写真になる
export function PropertyPhotoManager({ property, onChange }: Props) {
  const inputRef = useRef<HTMLInputElement>(null)
  const [errors, setErrors] = useState<string[]>([])
  const [busy, setBusy] = useState(false)
  // 削除ボタン付きの一覧は、閲覧時はギャラリーと重複するため「写真を管理」を押したときだけ出す
  const [editing, setEditing] = useState(false)

  const handleSelect = async (e: ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? [])
    e.target.value = '' // 同じファイルを続けて選び直せるようにする
    if (files.length === 0) return

    const invalid = validatePhotoFiles(files, property.photos.length)
    if (invalid.length > 0) {
      setErrors(invalid)
      return
    }

    setBusy(true)
    setErrors([])
    try {
      const res = await propertiesApi.uploadPhotos(property.id, files)
      onChange(res.data)
    } catch (err) {
      setErrors(err instanceof ApiError && err.details.photos ? err.details.photos : [errorMessage(err)])
    } finally {
      setBusy(false)
    }
  }

  const handleDelete = async (photoId: number, filename: string) => {
    if (!window.confirm(`写真「${filename}」を削除しますか？`)) return
    setBusy(true)
    setErrors([])
    try {
      const res = await propertiesApi.deletePhoto(property.id, photoId)
      onChange(res.data)
    } catch (err) {
      setErrors([errorMessage(err)])
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="photo-manager">
      <div className="section-header">
        <span className="muted small">
          {property.photos.length} / {MAX_PHOTOS} 枚（JPEG・PNG・WebP、1枚5MBまで。1枚目が一覧に表示されます）
        </span>
        <div className="actions">
          {property.photos.length > 0 && (
            <button type="button" className="btn btn-small" onClick={() => setEditing((v) => !v)} aria-expanded={editing}>
              {editing ? '管理を終了' : '写真を管理'}
            </button>
          )}
          <button
            type="button"
            className="btn btn-small"
            disabled={busy || property.photos.length >= MAX_PHOTOS}
            onClick={() => inputRef.current?.click()}
          >
            {busy ? '処理中...' : '＋ 写真を追加'}
          </button>
        </div>
        <input ref={inputRef} type="file" accept={PHOTO_TYPES.join(',')} multiple hidden onChange={handleSelect} aria-label="写真を選択" />
      </div>
      {errors.length > 0 && (
        <div className="alert alert-error">
          {errors.map((message) => (
            <div key={message}>{message}</div>
          ))}
        </div>
      )}
      {editing && property.photos.length > 0 && (
        <ul className="photo-list">
          {property.photos.map((photo, i) => (
            <li key={photo.id} className="photo-list-item">
              <img src={photo.thumbnail_url} alt={photo.filename} />
              {i === 0 && <span className="photo-cover">カバー</span>}
              <button type="button" className="photo-delete" disabled={busy} onClick={() => handleDelete(photo.id, photo.filename)} aria-label={`写真「${photo.filename}」を削除`}>
                ×
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
