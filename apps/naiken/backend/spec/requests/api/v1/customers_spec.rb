require "rails_helper"

RSpec.describe "Api::V1::Customers", type: :request do
  let(:agent) { create(:agent) }

  describe "GET /api/v1/customers" do
    it "更新日時の新しい順に一覧とページ情報を返す" do
      old = create(:customer, agent:, updated_at: 2.days.ago)
      recent = create(:customer, agent:, updated_at: 1.hour.ago)

      get "/api/v1/customers"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].pluck("id")).to eq [ recent.id, old.id ]
      expect(response.parsed_body["data"].first["agent"]).to include("id" => agent.id, "name" => agent.name)
      expect(response.parsed_body["meta"]).to eq("page" => 1, "per_page" => 20, "total_count" => 2, "total_pages" => 1)
    end

    it "キーワードと担当者で絞り込める" do
      other_agent = create(:agent)
      target = create(:customer, agent:, name: "山田 太郎")
      create(:customer, agent: other_agent, name: "山田 次郎")
      create(:customer, agent:, name: "田中 花子")

      get "/api/v1/customers", params: { q: "山田", agent_id: agent.id }

      expect(response.parsed_body["data"].pluck("id")).to eq [ target.id ]
    end

    it "per_page と page でページングできる" do
      customers = create_list(:customer, 3, agent:).sort_by(&:id).reverse

      get "/api/v1/customers", params: { page: 2, per_page: 2 }

      expect(response.parsed_body["data"].pluck("id")).to eq [ customers.last.id ]
      expect(response.parsed_body["meta"]).to include("page" => 2, "total_count" => 3, "total_pages" => 2)
    end
  end

  describe "GET /api/v1/customers/:id" do
    it "顧客の詳細を返す" do
      customer = create(:customer, agent:)

      get "/api/v1/customers/#{customer.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to include("id" => customer.id, "name" => customer.name)
    end

    it "存在しない場合は404を返す" do
      get "/api/v1/customers/0"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to include("code" => "not_found")
    end
  end

  describe "POST /api/v1/customers" do
    let(:valid_params) do
      { customer: { agent_id: agent.id, name: "山田 太郎", name_kana: "ヤマダ タロウ", email: "yamada@example.com", budget_max: 6000 } }
    end

    it "顧客を登録し201を返す" do
      expect {
        post "/api/v1/customers", params: valid_params, as: :json
      }.to change(Customer, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include("name" => "山田 太郎", "budget_max" => 6000)
    end

    it "入力に誤りがある場合は422と項目ごとのエラーを返す" do
      post "/api/v1/customers", params: { customer: { agent_id: agent.id, name: "", name_kana: "やまだ" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      error = response.parsed_body["error"]
      expect(error["code"]).to eq "validation_failed"
      expect(error["details"]["name"]).to eq [ "氏名を入力してください" ]
      expect(error["details"]["name_kana"]).to eq [ "フリガナは全角カタカナで入力してください" ]
    end

    it "customerキーのないJSONは自動でcustomerキーに包まれる(ParamsWrapper)" do
      post "/api/v1/customers", params: valid_params[:customer], as: :json

      expect(response).to have_http_status(:created)
    end

    it "customerキーがない場合(JSON以外)は400を返す" do
      post "/api/v1/customers", params: { name: "山田" }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to include("code" => "bad_request")
    end

    it "許可していない属性は無視する" do
      post "/api/v1/customers", params: valid_params.deep_merge(customer: { id: 9999 }), as: :json

      expect(response.parsed_body["data"]["id"]).not_to eq 9999
    end
  end

  describe "PATCH /api/v1/customers/:id" do
    let(:customer) { create(:customer, agent:, name: "山田 太郎") }

    it "顧客情報を更新する" do
      patch "/api/v1/customers/#{customer.id}", params: { customer: { name: "山田 一郎" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(customer.reload.name).to eq "山田 一郎"
    end

    it "入力に誤りがある場合は422を返し、更新しない" do
      patch "/api/v1/customers/#{customer.id}", params: { customer: { name: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(customer.reload.name).to eq "山田 太郎"
    end
  end

  describe "DELETE /api/v1/customers/:id" do
    it "顧客を削除し204を返す" do
      customer = create(:customer, agent:)

      expect {
        delete "/api/v1/customers/#{customer.id}"
      }.to change(Customer, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
