require "rails_helper"

RSpec.describe "エラーハンドリング", type: :request do
  it "存在しないURLはJSONの404を返す" do
    get "/api/v1/unknown"

    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq "application/json"
    expect(response.parsed_body["error"]).to include("code" => "route_not_found")
  end

  it "JSONとして解釈できないリクエストは400を返す" do
    post "/api/v1/customers", params: '{"customer": {"name": ', headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["error"]).to include("code" => "bad_request")
  end

  context "想定外のエラーが発生した場合" do
    before { allow(Customer).to receive(:includes).and_raise(RuntimeError, "secret internal detail") }

    it "本番相当の設定では、内部情報を含まない500とrequest_idを返す" do
      allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false)

      get "/api/v1/customers", headers: { "X-Request-Id" => "test-request-id" }

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body["error"]).to include("code" => "internal_server_error", "request_id" => "test-request-id")
      expect(response.body).not_to include("secret internal detail")
    end

    it "開発・テスト環境では原因を調べやすいよう例外をそのまま発生させる" do
      expect { get "/api/v1/customers" }.to raise_error(RuntimeError, "secret internal detail")
    end
  end
end
