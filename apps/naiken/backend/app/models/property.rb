# 顧客に紹介する売買物件
class Property < ApplicationRecord
  LAYOUT_FORMAT = /\A(\d{1,2}(R|K|DK|LDK|SK|SDK|SLDK)|ワンルーム)\z/
  MAX_PRICE = 1_000_000 # 100億円(万円単位)

  has_many :viewings, dependent: :restrict_with_error

  enum :status, { available: "available", closed: "closed" }, validate: true

  validates :name, presence: true, length: { maximum: 100 }
  validates :address, presence: true, length: { maximum: 255 }
  validates :price, presence: true
  validates :price, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_PRICE }, allow_nil: true
  validates :layout, format: { with: LAYOUT_FORMAT }, allow_blank: true
  validates :floor_area, numericality: { greater_than: 0, less_than: 10_000 }, allow_nil: true
  validates :built_year, numericality: { only_integer: true, greater_than_or_equal_to: 1900 }, allow_nil: true
  validate :built_year_not_too_far_future
  validates :nearest_station, length: { maximum: 50 }
  validates :walk_minutes, numericality: { only_integer: true, in: 0..120 }, allow_nil: true
  validates :note, length: { maximum: 2000 }

  normalizes :name, :address, with: ->(value) { value.strip }
  # 「３ｌｄｋ」のような全角・小文字の入力も「3LDK」にそろえる
  normalizes :layout, with: ->(value) { value.strip.tr("０-９ａ-ｚＡ-Ｚ", "0-9a-zA-Z").upcase.presence }
  normalizes :nearest_station, :note, with: ->(value) { value.strip.presence }

  # 物件名・住所・最寄り駅の部分一致で検索する
  scope :search, ->(keyword) {
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    where("name LIKE :q OR address LIKE :q OR nearest_station LIKE :q", q: pattern)
  }
  scope :price_between, ->(min, max) {
    scope = all
    scope = scope.where(price: min.to_i..) if min.present?
    scope = scope.where(price: ..max.to_i) if max.present?
    scope
  }

  private

  # 新築・建築予定の物件を考慮し、3年先までは許可する
  def built_year_not_too_far_future
    return if built_year.blank?

    errors.add(:built_year, :too_far_future) if built_year > Date.current.year + 3
  end
end
