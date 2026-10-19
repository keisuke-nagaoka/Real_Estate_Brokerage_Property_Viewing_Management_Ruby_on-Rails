require "rails_helper"

RSpec.describe "Api::V1::Agents", type: :request do
  describe "GET /api/v1/agents" do
    it "担当者の一覧を返す" do
      sato = create(:agent, name: "佐藤")
      suzuki = create(:agent, name: "鈴木")

      get "/api/v1/agents"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq [
        { "id" => sato.id, "name" => "佐藤", "email" => sato.email },
        { "id" => suzuki.id, "name" => "鈴木", "email" => suzuki.email }
      ]
    end
  end
end
