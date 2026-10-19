# 物件を探している顧客(購入検討者)
class Customer < ApplicationRecord
  KANA_FORMAT = /\A[ァ-ヶー　 ]+\z/
  PHONE_FORMAT = /\A0\d{1,4}-?\d{1,4}-?\d{3,4}\z/

  # 対応ステータスと、各ステータスから変更できる先
  STATUS_TRANSITIONS = {
    "inquiry" => %w[viewing_scheduled considering lost],
    "viewing_scheduled" => %w[considering contracted lost],
    "considering" => %w[viewing_scheduled contracted lost],
    "contracted" => [],
    "lost" => %w[inquiry]
  }.freeze
  CLOSED_STATUSES = %w[contracted lost].freeze

  belongs_to :agent
  has_many :viewings, dependent: :restrict_with_error

  enum :status, {
    inquiry: "inquiry",
    viewing_scheduled: "viewing_scheduled",
    considering: "considering",
    contracted: "contracted",
    lost: "lost"
  }, validate: true

  # 内見予定の有無より先に判定し、成約済みであることを理由として返す
  before_destroy :prevent_destroying_contracted, prepend: true

  validates :name, presence: true, length: { maximum: 50 }
  validates :name_kana, presence: true, length: { maximum: 50 }, format: { with: KANA_FORMAT, allow_blank: true }
  validates :email, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: PHONE_FORMAT }, allow_blank: true
  validates :budget_max, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :desired_area, length: { maximum: 100 }
  validates :note, length: { maximum: 2000 }
  validate :status_transition_must_be_allowed, on: :update, if: :will_save_change_to_status?

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
  scope :active, -> { where.not(status: CLOSED_STATUSES) }

  # 成約・失注になった顧客(案件が終了した顧客)
  def closed?
    CLOSED_STATUSES.include?(status)
  end

  def next_statuses
    STATUS_TRANSITIONS.fetch(status_in_database.to_s, [])
  end

  # ステータスを変更する。成約・失注になった場合は、残っている内見予定をキャンセルする
  # 戻り値: 成功したら true。キャンセルした内見予定の件数は canceled_viewings_count で参照できる
  def change_status(new_status)
    @canceled_viewings_count = 0
    transaction do
      self.status = new_status
      raise ActiveRecord::Rollback unless save

      @canceled_viewings_count = viewings.scheduled.update_all(status: "canceled", updated_at: Time.current) if closed?
    end
    errors.empty?
  end

  def canceled_viewings_count
    @canceled_viewings_count.to_i
  end

  # 内見予定の登録・実施に合わせてステータスを自動で進める
  def advance_status_for_new_viewing!
    update!(status: :viewing_scheduled) if inquiry? || considering?
  end

  def advance_status_for_completed_viewing!
    update!(status: :considering) if viewing_scheduled? && viewings.scheduled.none?
  end

  private

  def status_transition_must_be_allowed
    return unless self.class.statuses.key?(status) # 未定義の値は enum のバリデーションでエラーにする
    return if next_statuses.include?(status)

    errors.add(:status, :invalid_transition,
               from: self.class.human_attribute_name("status/#{status_in_database}"),
               to: self.class.human_attribute_name("status/#{status}"))
  end

  def prevent_destroying_contracted
    return unless contracted?

    errors.add(:base, :contracted_cannot_be_destroyed)
    throw :abort
  end
end
