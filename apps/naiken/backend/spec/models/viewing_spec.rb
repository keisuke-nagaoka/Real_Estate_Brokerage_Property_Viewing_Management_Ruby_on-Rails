require "rails_helper"

RSpec.describe Viewing, type: :model do
  let(:agent) { create(:agent) }
  let(:customer) { create(:customer, agent:) }
  let(:property) { create(:property) }
  let(:base_time) { 1.day.from_now.change(hour: 10, min: 0) }

  def build_viewing(starts_at:, ends_at:, **attrs)
    build(:viewing, customer:, property:, agent:, starts_at:, ends_at:, **attrs)
  end

  it "ファクトリのデータは有効である" do
    expect(build(:viewing)).to be_valid
  end

  describe "日時" do
    it "開始・終了日時は必須である" do
      viewing = build_viewing(starts_at: nil, ends_at: nil)

      expect(viewing).to be_invalid
      expect(viewing.errors.full_messages).to include("開始日時を入力してください", "終了日時を入力してください")
    end

    it "終了日時は開始日時より後でなければならない" do
      viewing = build_viewing(starts_at: base_time, ends_at: base_time)

      expect(viewing).to be_invalid
      expect(viewing.errors.full_messages).to include("終了日時は開始日時より後にしてください")
    end
  end

  describe "業務ルール: 担当者の予定の重複" do
    before { create(:viewing, customer:, property:, agent:, starts_at: base_time, ends_at: base_time + 1.hour) }

    it "同じ担当者の予定と時間帯が重なる場合は登録できない" do
      viewing = build_viewing(starts_at: base_time + 30.minutes, ends_at: base_time + 90.minutes)

      expect(viewing).to be_invalid
      expect(viewing.errors[:base].first).to match(/担当者の別の内見予定（.+ 10:00〜11:00）と時間が重複しています/)
    end

    it "既存の予定を内側に含む時間帯も登録できない" do
      expect(build_viewing(starts_at: base_time - 1.hour, ends_at: base_time + 2.hours)).to be_invalid
    end

    it "終了時刻ちょうどから始まる予定は登録できる" do
      expect(build_viewing(starts_at: base_time + 1.hour, ends_at: base_time + 2.hours)).to be_valid
    end

    it "別の担当者であれば同じ時間帯でも登録できる" do
      other = create(:agent)

      expect(build_viewing(starts_at: base_time, ends_at: base_time + 1.hour, agent: other)).to be_valid
    end

    it "キャンセル済みの予定とは重複してもよい" do
      Viewing.last.cancel

      expect(build_viewing(starts_at: base_time, ends_at: base_time + 1.hour)).to be_valid
    end

    it "自分自身の時間を変更する場合は重複とみなさない" do
      viewing = Viewing.last

      expect(viewing.update(ends_at: base_time + 2.hours)).to be true
    end
  end

  describe "業務ルール: 掲載終了の物件" do
    it "掲載終了の物件には内見予定を登録できない" do
      viewing = build_viewing(starts_at: base_time, ends_at: base_time + 1.hour, property: create(:property, :closed))

      expect(viewing).to be_invalid
      expect(viewing.errors.full_messages).to include("物件は掲載終了のため、内見予定を登録できません")
    end

    it "予定登録後に物件が掲載終了になっても、物件を変えなければ時間は変更できる" do
      viewing = create(:viewing, property:, starts_at: base_time, ends_at: base_time + 1.hour)
      property.update!(status: "closed")

      expect(viewing.update(ends_at: base_time + 2.hours)).to be true
    end
  end

  describe "#complete" do
    it "開始時刻を過ぎた予定を実施済みにできる" do
      viewing = create(:viewing, starts_at: 1.hour.ago, ends_at: Time.current)

      expect(viewing.complete).to be true
      expect(viewing.reload).to be_completed
    end

    it "開始時刻前の予定は実施済みにできない" do
      viewing = create(:viewing, starts_at: base_time, ends_at: base_time + 1.hour)

      expect(viewing.complete).to be false
      expect(viewing.errors[:base]).to eq [ "開始時刻前の内見予定は実施済みにできません" ]
      expect(viewing.reload).to be_scheduled
    end

    it "キャンセル済みの予定は実施済みにできない" do
      viewing = create(:viewing, :canceled)

      expect(viewing.complete).to be false
      expect(viewing.errors[:base]).to eq [ "キャンセルの内見予定は変更できません" ]
    end
  end

  describe "#cancel" do
    it "予定をキャンセルできる" do
      viewing = create(:viewing)

      expect(viewing.cancel).to be true
      expect(viewing.reload).to be_canceled
    end

    it "実施済みの予定はキャンセルできない" do
      viewing = create(:viewing, :completed)

      expect(viewing.cancel).to be false
      expect(viewing.errors[:base]).to eq [ "実施済みの内見予定は変更できません" ]
    end
  end

  describe "業務ルール: 実施済み・キャンセル済みの予定の変更" do
    it "実施済みの予定は日時やメモを変更できない" do
      viewing = create(:viewing, :completed)

      expect(viewing.update(note: "変更")).to be false
      expect(viewing.errors[:base]).to eq [ "実施済みの内見予定は変更できません" ]
    end
  end

  describe "業務ルール: 履歴の保護" do
    it "内見予定のある顧客・物件・担当者は削除できない" do
      viewing = create(:viewing)

      expect(viewing.customer.destroy).to be false
      expect(viewing.customer.errors.full_messages).to include("内見予定が存在しているので削除できません")
      expect(viewing.property.destroy).to be false
      expect(viewing.agent.destroy).to be false
    end
  end

  describe "#save_with_agent_lock" do
    it "担当者の行をロックしてから保存する" do
      viewing = build_viewing(starts_at: base_time, ends_at: base_time + 1.hour)
      allow(Agent).to receive(:lock).and_call_original

      expect(viewing.save_with_agent_lock).to be true
      expect(Agent).to have_received(:lock)
    end

    it "バリデーションエラーの場合は false を返す" do
      viewing = build_viewing(starts_at: base_time, ends_at: base_time - 1.hour)

      expect(viewing.save_with_agent_lock).to be false
      expect(viewing).not_to be_persisted
    end
  end
end
