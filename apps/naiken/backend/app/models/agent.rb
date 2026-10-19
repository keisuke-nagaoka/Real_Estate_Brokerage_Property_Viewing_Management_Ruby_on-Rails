# 不動産仲介の営業担当者
class Agent < ApplicationRecord
  has_many :customers, dependent: :restrict_with_error
  has_many :viewings, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }

  normalizes :email, with: ->(email) { email.strip.downcase }
end
