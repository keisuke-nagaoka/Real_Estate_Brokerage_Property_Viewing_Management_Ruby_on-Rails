require "rails_helper"

RSpec.describe "Api::V1::Viewings", type: :request do
  let(:agent) { create(:agent) }
  let(:customer) { create(:customer, agent:) }
  let(:property) { create(:property) }
  let(:tomorrow_10) { 1.day.from_now.change(hour: 10, min: 0) }

  describe "GET /api/v1/viewings" do
    it "開始日時の近い順に、顧客・物件・担当者を含めて返す" do
      later = create(:viewing, customer:, property:, starts_at: tomorrow_10 + 2.hours)
      sooner = create(:viewing, customer:, property:, starts_at: tomorrow_10)

      get "/api/v1/viewings"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.pluck("id")).to eq [ sooner.id, later.id ]
      expect(data.first).to include(
        "status" => "scheduled",
        "customer" => { "id" => customer.id, "name" => customer.name },
        "agent" => { "id" => agent.id, "name" => agent.name }
      )
    end

    it "期間・担当者・顧客・物件・ステータスで絞り込める" do
      target = create(:viewing, customer:, property:, starts_at: tomorrow_10)
      create(:viewing, customer:, property:, starts_at: tomorrow_10 + 7.days)
      create(:viewing, starts_at: tomorrow_10)
      create(:viewing, :completed, customer:, property:)

      date = tomorrow_10.to_date.iso8601
      get "/api/v1/viewings", params: { from: date, to: date, agent_id: agent.id, customer_id: customer.id, property_id: property.id, status: "scheduled" }

      expect(response.parsed_body["data"].pluck("id")).to eq [ target.id ]
    end

    it "order=desc の場合は新しい順に返す" do
      older = create(:viewing, :completed, starts_at: 3.days.ago)
      newer = create(:viewing, :completed, starts_at: 1.day.ago)

      get "/api/v1/viewings", params: { order: "desc" }

      expect(response.parsed_body["data"].pluck("id")).to eq [ newer.id, older.id ]
    end

    it "日付の形式が不正な場合は400を返す" do
      get "/api/v1/viewings", params: { from: "2026/10/01" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/v1/viewings" do
    let(:params) do
      { viewing: { customer_id: customer.id, property_id: property.id, agent_id: agent.id,
                   starts_at: "#{tomorrow_10.to_date.iso8601}T10:00:00+09:00",
                   ends_at: "#{tomorrow_10.to_date.iso8601}T11:00:00+09:00" } }
    end

    it "内見予定を登録し201を返す" do
      expect {
        post "/api/v1/viewings", params:, as: :json
      }.to change(Viewing, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Viewing.last).to have_attributes(starts_at: tomorrow_10, status: "scheduled")
    end

    it "担当者の予定と重複する場合は422を返す" do
      create(:viewing, customer:, property:, agent:, starts_at: tomorrow_10 + 30.minutes, ends_at: tomorrow_10 + 90.minutes)

      post "/api/v1/viewings", params:, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["message"]).to include("時間が重複しています")
      expect(response.parsed_body["error"]["details"]["base"]).to be_present
    end

    it "掲載終了の物件の場合は422を返す" do
      post "/api/v1/viewings", params: params.deep_merge(viewing: { property_id: create(:property, :closed).id }), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["details"]["property"]).to eq [ "物件は掲載終了のため、内見予定を登録できません" ]
    end

    it "成約の顧客の場合は422を返す" do
      customer.update_column(:status, "contracted")

      post "/api/v1/viewings", params:, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["details"]["customer"]).to eq [ "顧客が成約のため、内見予定を登録できません" ]
    end

    it "登録すると顧客のステータスが「内見予定」に進む" do
      post "/api/v1/viewings", params:, as: :json

      expect(customer.reload).to be_viewing_scheduled
    end

    it "ステータスは指定できない(常に予定として登録する)" do
      post "/api/v1/viewings", params: params.deep_merge(viewing: { status: "completed" }), as: :json

      expect(response.parsed_body["data"]["status"]).to eq "scheduled"
    end
  end

  describe "PATCH /api/v1/viewings/:id" do
    it "日時を変更する" do
      viewing = create(:viewing, customer:, property:, starts_at: tomorrow_10)

      patch "/api/v1/viewings/#{viewing.id}", params: { viewing: { starts_at: tomorrow_10 + 1.hour, ends_at: tomorrow_10 + 2.hours } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(viewing.reload.starts_at).to eq tomorrow_10 + 1.hour
    end

    it "実施済みの予定は変更できず422を返す" do
      viewing = create(:viewing, :completed)

      patch "/api/v1/viewings/#{viewing.id}", params: { viewing: { note: "変更" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["message"]).to eq "実施済みの内見予定は変更できません"
    end
  end

  describe "PATCH /api/v1/viewings/:id/complete" do
    it "開始時刻を過ぎた予定を実施済みにする" do
      viewing = create(:viewing, starts_at: 2.hours.ago, ends_at: 1.hour.ago)

      patch "/api/v1/viewings/#{viewing.id}/complete"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["status"]).to eq "completed"
    end

    it "開始時刻前の予定は422を返す" do
      viewing = create(:viewing, starts_at: tomorrow_10)

      patch "/api/v1/viewings/#{viewing.id}/complete"

      expect(response).to have_http_status(:unprocessable_content)
      expect(viewing.reload).to be_scheduled
    end
  end

  describe "PATCH /api/v1/viewings/:id/cancel" do
    it "予定をキャンセルする" do
      viewing = create(:viewing)

      patch "/api/v1/viewings/#{viewing.id}/cancel"

      expect(response).to have_http_status(:ok)
      expect(viewing.reload).to be_canceled
    end
  end

  describe "履歴の保護" do
    it "内見予定のある顧客・物件は削除できず422を返す" do
      viewing = create(:viewing)

      delete "/api/v1/customers/#{viewing.customer_id}"
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["message"]).to eq "内見予定が存在しているので削除できません"

      delete "/api/v1/properties/#{viewing.property_id}"
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
