import { describe, expect, it } from 'vitest'
import { formatDateLabel, toDateInput, toIso, toTimeInput } from './datetime'

describe('日本時間での日時の扱い', () => {
  it('UTCで前日の日時も、日本時間の日付・時刻に変換する', () => {
    // 2026-10-19 16:30 UTC = 2026-10-20 01:30 JST
    const iso = '2026-10-19T16:30:00Z'

    expect(toDateInput(iso)).toBe('2026-10-20')
    expect(toTimeInput(iso)).toBe('01:30')
  })

  it('日付と時刻の入力値から、日本時間のオフセット付きISO文字列を作る', () => {
    expect(toIso('2026-10-20', '10:00')).toBe('2026-10-20T10:00:00+09:00')
    expect(toIso('', '10:00')).toBe('')
  })

  it('toIso で作った文字列を戻すと元の入力値になる', () => {
    const iso = toIso('2026-10-20', '23:45')

    expect(toDateInput(iso)).toBe('2026-10-20')
    expect(toTimeInput(iso)).toBe('23:45')
  })

  it('一覧の見出し用に「10月20日(火)」の形式にする', () => {
    expect(formatDateLabel('2026-10-20T10:00:00+09:00')).toBe('10月20日(火)')
  })
})
