require "rails_helper"

RSpec.describe "Api::V1::Properties", type: :request do
  describe "GET /api/v1/properties" do
    it "更新日時の新しい順に一覧とページ情報を返す" do
      old = create(:property, updated_at: 2.days.ago)
      recent = create(:property, updated_at: 1.hour.ago, floor_area: 72.45)

      get "/api/v1/properties"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.pluck("id")).to eq [ recent.id, old.id ]
      expect(data.first["floor_area"]).to eq 72.45
      expect(response.parsed_body["meta"]).to include("total_count" => 2)
    end

    it "キーワード・掲載状況・価格帯で絞り込める" do
      target = create(:property, name: "パークハウス世田谷", price: 5000)
      create(:property, name: "パークハウス世田谷 別棟", price: 9000)
      create(:property, :closed, name: "パークハウス世田谷 旧", price: 5000)
      create(:property, name: "プラウド目黒", price: 5000)

      get "/api/v1/properties", params: { q: "パークハウス", status: "available", price_min: 4000, price_max: 6000 }

      expect(response.parsed_body["data"].pluck("id")).to eq [ target.id ]
    end

    it "未定義の掲載状況が指定された場合は絞り込まない" do
      create_list(:property, 2)

      get "/api/v1/properties", params: { status: "unknown" }

      expect(response.parsed_body["meta"]["total_count"]).to eq 2
    end
  end

  describe "GET /api/v1/properties/:id" do
    it "物件の詳細を返す" do
      property = create(:property)

      get "/api/v1/properties/#{property.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to include("id" => property.id, "status" => "available")
    end

    it "存在しない場合は404を返す" do
      get "/api/v1/properties/0"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/properties" do
    it "物件を登録し201を返す" do
      params = { property: { name: "パークハウス世田谷", address: "東京都世田谷区", price: 5980, layout: "３ldk", floor_area: "72.4" } }

      expect {
        post "/api/v1/properties", params:, as: :json
      }.to change(Property, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include("name" => "パークハウス世田谷", "layout" => "3LDK", "floor_area" => 72.4, "status" => "available")
    end

    it "入力に誤りがある場合は422と項目ごとのエラーを返す" do
      post "/api/v1/properties", params: { property: { name: "", address: "東京都", price: 0, status: "unknown" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      details = response.parsed_body["error"]["details"]
      expect(details.keys).to contain_exactly("name", "price", "status")
    end
  end

  describe "PATCH /api/v1/properties/:id" do
    it "掲載状況を含めて物件情報を更新する" do
      property = create(:property, price: 5000)

      patch "/api/v1/properties/#{property.id}", params: { property: { price: 4800, status: "closed" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(property.reload).to have_attributes(price: 4800, status: "closed")
    end
  end

  describe "DELETE /api/v1/properties/:id" do
    it "物件を削除し204を返す" do
      property = create(:property)

      expect {
        delete "/api/v1/properties/#{property.id}"
      }.to change(Property, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
