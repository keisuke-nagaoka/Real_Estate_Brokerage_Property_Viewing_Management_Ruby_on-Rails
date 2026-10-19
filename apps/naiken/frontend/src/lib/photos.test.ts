import { describe, expect, it } from 'vitest'
import { MAX_PHOTO_SIZE, validatePhotoFiles } from './photos'

function file(name: string, type: string, size = 1024): File {
  const f = new File(['x'], name, { type })
  Object.defineProperty(f, 'size', { value: size })
  return f
}

describe('validatePhotoFiles', () => {
  it('JPEG・PNG・WebP で5MB以下ならエラーにしない', () => {
    expect(validatePhotoFiles([file('a.jpg', 'image/jpeg'), file('b.png', 'image/png'), file('c.webp', 'image/webp')], 0)).toEqual([])
  })

  it('画像以外・5MB超のファイルはエラーにする', () => {
    expect(validatePhotoFiles([file('a.pdf', 'application/pdf'), file('b.jpg', 'image/jpeg', MAX_PHOTO_SIZE + 1)], 0)).toEqual([
      '「a.pdf」はJPEG・PNG・WebP形式の画像にしてください',
      '「b.jpg」は5MB以下にしてください',
    ])
  })

  it('登録済みの枚数と合わせて10枚を超える場合はエラーにする', () => {
    expect(validatePhotoFiles([file('a.jpg', 'image/jpeg'), file('b.jpg', 'image/jpeg')], 9)).toEqual(['写真は10枚まで登録できます（あと1枚）'])
  })
})
