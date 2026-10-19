import { describe, expect, it, vi } from 'vitest'
import { formatAccess, formatBudget, formatBuildingAge, formatPrice } from './format'

describe('formatPrice', () => {
  it.each([
    [3980, '3,980万円'],
    [10000, '1億円'],
    [12800, '1億2,800万円'],
    [100000, '10億円'],
  ])('%i万円 → %s', (manYen, expected) => {
    expect(formatPrice(manYen)).toBe(expected)
  })
})

describe('formatBudget', () => {
  it('未設定の場合は「-」を返す', () => {
    expect(formatBudget(null)).toBe('-')
    expect(formatBudget(6000)).toBe('6,000万円')
  })
})

describe('formatBuildingAge', () => {
  it('現在の年から築年数を計算する', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-10-19T12:00:00+09:00'))

    expect(formatBuildingAge(2015)).toBe('築11年')
    expect(formatBuildingAge(2026)).toBe('新築')
    expect(formatBuildingAge(2028)).toBe('新築')
    expect(formatBuildingAge(null)).toBe('築年不明')
  })
})

describe('formatAccess', () => {
  it('駅名と徒歩分数を組み合わせる', () => {
    expect(formatAccess('渋谷', 7)).toBe('渋谷駅 徒歩7分')
    expect(formatAccess('渋谷', null)).toBe('渋谷駅')
    expect(formatAccess(null, 7)).toBe('-')
  })
})
