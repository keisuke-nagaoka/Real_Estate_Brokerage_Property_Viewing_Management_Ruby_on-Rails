# 顧客と物件を紐づけた内見予定
class Viewing < ApplicationRecord
  belongs_to :customer
  belongs_to :property
  belongs_to :agent

  enum :status, { scheduled: "scheduled", completed: "completed", canceled: "canceled" }, validate: true

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :note, length: { maximum: 2000 }
  validate :ends_after_starts
  validate :property_must_be_available
  validate :agent_schedule_must_not_overlap
  validate :only_scheduled_can_be_changed, on: :update

  normalizes :note, with: ->(value) { value.strip.presence }

  scope :overlapping, ->(starts_at, ends_at) { where("starts_at < ? AND ends_at > ?", ends_at, starts_at) }
  scope :starts_on_or_after, ->(date) { where(starts_at: date.in_time_zone.beginning_of_day..) }
  scope :starts_on_or_before, ->(date) { where(starts_at: ..date.in_time_zone.end_of_day) }

  # 重複チェックと保存の間に別リクエストが同じ担当者の予定を登録しないよう、
  # 担当者の行をロックしてから保存する(同じ担当者への登録を直列化する)
  def save_with_agent_lock
    transaction do
      Agent.lock.find_by(id: agent_id)
      save
    end
  end

  def complete
    return false unless ensure_scheduled

    if starts_at.future?
      errors.add(:base, :not_started_yet)
      return false
    end
    update(status: :completed)
  end

  def cancel
    return false unless ensure_scheduled

    update(status: :canceled)
  end

  private

  def ensure_scheduled
    return true if scheduled?

    errors.add(:base, :already_closed, status: self.class.human_attribute_name("status/#{status}"))
    false
  end

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, :must_be_after_starts_at) if ends_at <= starts_at
  end

  # 掲載終了の物件には新しく内見予定を入れられない(既存の予定の変更は物件を変えない限り許可する)
  def property_must_be_available
    return unless property&.closed?
    return unless new_record? || will_save_change_to_property_id?

    errors.add(:property, :closed)
  end

  def agent_schedule_must_not_overlap
    return unless scheduled? && agent_id.present? && starts_at.present? && ends_at.present?

    conflict = Viewing.scheduled.where(agent_id:).where.not(id:).overlapping(starts_at, ends_at).order(:starts_at).first
    return if conflict.nil?

    errors.add(:base, :agent_schedule_overlap,
               starts_at: I18n.l(conflict.starts_at, format: "%m/%d %H:%M"),
               ends_at: I18n.l(conflict.ends_at, format: "%H:%M"))
  end

  def only_scheduled_can_be_changed
    return if status_in_database == "scheduled"

    errors.add(:base, :already_closed, status: self.class.human_attribute_name("status/#{status_in_database}"))
  end
end
