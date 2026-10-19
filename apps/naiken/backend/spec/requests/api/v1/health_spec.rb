require "rails_helper"

RSpec.describe "Api::V1::Health", type: :request do
  describe "GET /api/v1/health" do
    it "DBに接続できる場合は200とステータスを返す" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("status" => "ok", "database" => "ok", "environment" => "test")
    end

    it "DBに接続できない場合は503を返す" do
      allow(ActiveRecord::Base.connection).to receive(:select_value)
        .and_raise(ActiveRecord::ConnectionNotEstablished)

      get "/api/v1/health"

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body).to include("status" => "error", "database" => "unavailable")
    end
  end
end
