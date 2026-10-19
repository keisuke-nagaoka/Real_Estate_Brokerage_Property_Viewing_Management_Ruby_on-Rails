# 物件を探している顧客(購入検討者)
class Customer < ApplicationRecord
  KANA_FORMAT = /\A[ァ-ヶー　 ]+\z/
  PHONE_FORMAT = /\A0\d{1,4}-?\d{1,4}-?\d{3,4}\z/

  belongs_to :agent

  validates :name, presence: true, length: { maximum: 50 }
  validates :name_kana, presence: true, length: { maximum: 50 }, format: { with: KANA_FORMAT, allow_blank: true }
  validates :email, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: PHONE_FORMAT }, allow_blank: true
  validates :budget_max, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :desired_area, length: { maximum: 100 }
  validates :note, length: { maximum: 2000 }

  normalizes :email, with: ->(email) { email.strip.downcase.presence }
  normalizes :phone, with: ->(phone) { phone.strip.tr("０-９－", "0-9-").presence }
  normalizes :name, :name_kana, with: ->(value) { value.strip }
  normalizes :desired_area, :note, with: ->(value) { value.strip.presence }

  # 氏名・フリガナ・メールアドレス・電話番号の部分一致で検索する
  scope :search, ->(keyword) {
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    where("name LIKE :q OR name_kana LIKE :q OR email LIKE :q OR phone LIKE :q", q: pattern)
  }
end
