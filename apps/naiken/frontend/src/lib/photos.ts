// サーバー側(Property モデル)と同じ条件を、アップロード前に画面でも確認する
export const PHOTO_TYPES = ['image/jpeg', 'image/png', 'image/webp']
export const MAX_PHOTO_SIZE = 5 * 1024 * 1024
export const MAX_PHOTOS = 10

export function validatePhotoFiles(files: File[], currentCount: number): string[] {
  const errors: string[] = []
  if (currentCount + files.length > MAX_PHOTOS) {
    errors.push(`写真は${MAX_PHOTOS}枚まで登録できます（あと${Math.max(0, MAX_PHOTOS - currentCount)}枚）`)
  }
  for (const file of files) {
    if (!PHOTO_TYPES.includes(file.type)) errors.push(`「${file.name}」はJPEG・PNG・WebP形式の画像にしてください`)
    else if (file.size > MAX_PHOTO_SIZE) errors.push(`「${file.name}」は5MB以下にしてください`)
  }
  return errors
}
