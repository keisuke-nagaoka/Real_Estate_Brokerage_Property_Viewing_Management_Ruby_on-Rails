# 顧客に紹介する売買物件
class Property < ApplicationRecord
  # 都道府県(JIS X 0401 の順)。エリアの一覧もこの順に並べる
  PREFECTURES = %w[
    北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県
    茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県
    新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県
    三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県
    鳥取県 島根県 岡山県 広島県 山口県
    徳島県 香川県 愛媛県 高知県
    福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県
  ].freeze
  LAYOUT_FORMAT = /\A(\d{1,2}(R|K|DK|LDK|SK|SDK|SLDK)|ワンルーム)\z/
  MAX_PRICE = 1_000_000 # 100億円(万円単位)
  PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTO_SIZE = 5.megabytes
  MAX_PHOTOS = 10

  has_many :viewings, dependent: :restrict_with_error
  # 1枚目を一覧のカバー写真として使う。サイズ違いの画像(variant)は初回表示時に生成される
  has_many_attached :photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 640, 427 ]
    attachable.variant :large, resize_to_limit: [ 1600, 1200 ]
  end

  enum :status, { available: "available", closed: "closed" }, validate: true

  validates :name, presence: true, length: { maximum: 100 }
  validates :prefecture, presence: true, inclusion: { in: PREFECTURES, allow_blank: true }
  validates :city, presence: true, length: { maximum: 50 }
  validates :address_line, presence: true, length: { maximum: 200 }
  validates :price, presence: true
  validates :price, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_PRICE }, allow_nil: true
  validates :layout, format: { with: LAYOUT_FORMAT }, allow_blank: true
  validates :floor_area, numericality: { greater_than: 0, less_than: 10_000 }, allow_nil: true
  validates :built_year, numericality: { only_integer: true, greater_than_or_equal_to: 1900 }, allow_nil: true
  validate :built_year_not_too_far_future
  validate :photos_must_be_valid
  validates :nearest_station, length: { maximum: 50 }
  validates :walk_minutes, numericality: { only_integer: true, in: 0..120 }, allow_nil: true
  validates :note, length: { maximum: 2000 }

  normalizes :name, :prefecture, :city, :address_line, with: ->(value) { value.strip }
  # 「３ｌｄｋ」のような全角・小文字の入力も「3LDK」にそろえる
  normalizes :layout, with: ->(value) { value.strip.tr("０-９ａ-ｚＡ-Ｚ", "0-9a-zA-Z").upcase.presence }
  normalizes :nearest_station, :note, with: ->(value) { value.strip.presence }

  # 物件名・住所・最寄り駅の部分一致で検索する(住所は「世田谷区桜丘」のように区切りをまたいでも検索できる)
  scope :search, ->(keyword) {
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    where("name LIKE :q OR CONCAT(prefecture, city, address_line) LIKE :q OR nearest_station LIKE :q", q: pattern)
  }
  scope :in_area, ->(prefecture, city = nil) {
    scope = all
    scope = scope.where(prefecture:) if prefecture.present?
    scope = scope.where(city:) if city.present?
    scope
  }
  scope :price_between, ->(min, max) {
    scope = all
    scope = scope.where(price: min.to_i..) if min.present?
    scope = scope.where(price: ..max.to_i) if max.present?
    scope
  }

  # 物件があるエリア(都道府県・市区町村)と件数を、都道府県コード順・市区町村名順で返す
  # 例: [{ prefecture: "東京都", count: 8, cities: [{ name: "港区", count: 1 }, ...] }, ...]
  def self.areas
    group(:prefecture, :city).count
      .group_by { |(prefecture, _city), _count| prefecture }
      .sort_by { |prefecture, _| PREFECTURES.index(prefecture) || PREFECTURES.size }
      .map do |prefecture, rows|
        cities = rows.map { |(_prefecture, city), count| { name: city, count: } }.sort_by { it[:name] }
        { prefecture:, count: cities.sum { it[:count] }, cities: }
      end
  end

  def address
    "#{prefecture}#{city}#{address_line}"
  end

  private

  # 形式は送られてきた Content-Type ではなく、Active Storage がファイルの中身から判定した値で確認する
  def photos_must_be_valid
    return unless photos.attached?

    errors.add(:photos, :too_many, count: MAX_PHOTOS) if photos.size > MAX_PHOTOS
    photos.each do |photo|
      filename = photo.filename.to_s
      errors.add(:photos, :invalid_content_type, filename:) unless PHOTO_CONTENT_TYPES.include?(photo.content_type)
      errors.add(:photos, :too_large, filename:, size: "#{MAX_PHOTO_SIZE / 1.megabyte}MB") if photo.byte_size > MAX_PHOTO_SIZE
    end
  end

  # 新築・建築予定の物件を考慮し、3年先までは許可する
  def built_year_not_too_far_future
    return if built_year.blank?

    errors.add(:built_year, :too_far_future) if built_year > Date.current.year + 3
  end
end
