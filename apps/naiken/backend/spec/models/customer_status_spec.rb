require "rails_helper"

RSpec.describe Customer, "対応ステータス", type: :model do
  it "新規登録時は「問い合わせ」になる" do
    expect(create(:customer)).to be_inquiry
  end

  describe "#change_status" do
    allowed = {
      "inquiry" => %w[viewing_scheduled considering lost],
      "viewing_scheduled" => %w[considering contracted lost],
      "considering" => %w[viewing_scheduled contracted lost],
      "lost" => %w[inquiry]
    }
    all = Customer.statuses.keys

    allowed.each do |from, tos|
      tos.each do |to|
        it "「#{from}」から「#{to}」に変更できる" do
          customer = create(:customer)
          customer.update_column(:status, from)

          expect(customer.change_status(to)).to be true
          expect(customer.reload.status).to eq to
        end
      end

      (all - tos - [ from ]).each do |to|
        it "「#{from}」から「#{to}」には変更できない" do
          customer = create(:customer)
          customer.update_column(:status, from)

          expect(customer.change_status(to)).to be false
          expect(customer.reload.status).to eq from
        end
      end
    end

    it "成約になった顧客はどのステータスにも変更できない" do
      customer = create(:customer, :contracted)

      expect(customer.next_statuses).to be_empty
      expect(customer.change_status("lost")).to be false
      expect(customer.errors.full_messages).to eq [ "対応ステータスを「成約」から「失注」に変更することはできません" ]
    end

    it "未定義のステータスはエラーにする" do
      customer = create(:customer)

      expect(customer.change_status("unknown")).to be false
      expect(customer.errors.full_messages).to eq [ "対応ステータスは一覧にありません" ]
    end

    it "成約になったら、残っている内見予定をキャンセルする" do
      customer = create(:customer)
      tomorrow = 1.day.from_now.change(hour: 10)
      scheduled = [ 0, 2 ].map { |h| create(:viewing, customer:, starts_at: tomorrow + h.hours, ends_at: tomorrow + (h + 1).hours) }
      completed = create(:viewing, :completed, customer:)

      expect(customer.reload).to be_viewing_scheduled
      expect(customer.change_status("contracted")).to be true
      expect(customer.canceled_viewings_count).to eq 2
      expect(scheduled.map { it.reload.status }).to all(eq "canceled")
      expect(completed.reload).to be_completed
    end

    it "失注になった場合も、残っている内見予定をキャンセルする" do
      viewing = create(:viewing)

      expect(viewing.customer.reload.change_status("lost")).to be true
      expect(viewing.reload).to be_canceled
    end

    it "変更に失敗した場合は内見予定をキャンセルしない" do
      viewing = create(:viewing)
      customer = viewing.customer.reload

      expect(customer.change_status("inquiry")).to be false
      expect(customer.canceled_viewings_count).to eq 0
      expect(viewing.reload).to be_scheduled
    end
  end

  describe "通常の更新" do
    it "許可されていない遷移は通常の update でも保存できない" do
      customer = create(:customer)

      expect(customer.update(status: "contracted")).to be false
    end
  end

  describe "削除" do
    it "成約済みの顧客は削除できない" do
      customer = create(:customer, :contracted)

      expect(customer.destroy).to be false
      expect(customer.errors.full_messages).to eq [ "成約済みの顧客は削除できません" ]
    end
  end

  describe "内見予定に合わせた自動遷移" do
    it "内見予定を登録すると「問い合わせ」から「内見予定」に進む" do
      viewing = create(:viewing)

      expect(viewing.customer.reload).to be_viewing_scheduled
    end

    it "「検討中」の顧客に内見予定を登録すると「内見予定」に戻る" do
      customer = create(:customer, :considering)
      create(:viewing, customer:)

      expect(customer.reload).to be_viewing_scheduled
    end

    it "予定中の内見がすべて実施済みになると「検討中」に進む" do
      customer = create(:customer)
      first = create(:viewing, customer:, starts_at: 3.hours.ago, ends_at: 2.hours.ago)
      second = create(:viewing, customer:, starts_at: 2.hours.ago, ends_at: 1.hour.ago)

      first.complete
      expect(customer.reload).to be_viewing_scheduled

      second.complete
      expect(customer.reload).to be_considering
    end
  end
end
