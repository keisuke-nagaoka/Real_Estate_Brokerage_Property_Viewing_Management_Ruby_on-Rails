class ApplicationController < ActionController::API
  # rescue_from は後に書いたものが優先されるため、想定外のエラー(StandardError)を最初に書く
  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, ActionController::BadRequest,
              ActionDispatch::Http::Parameters::ParseError, with: :render_bad_request

  # どのルートにも一致しないURL(config/routes.rb の最後で受ける)
  def route_not_found
    render_error(status: :not_found, code: "route_not_found", message: "指定されたURLは存在しません")
  end

  private

  # エラーレスポンスは { error: { code:, message:, details: } } の形式に統一する
  def render_error(status:, code:, message:, details: nil, **extra)
    body = { error: { code:, message:, details:, **extra }.compact }
    render json: body, status:
  end

  def render_validation_error(record)
    render_error(
      status: :unprocessable_content,
      code: "validation_failed",
      message: record.errors.full_messages.first || "入力内容に誤りがあります",
      details: record.errors.to_hash(true)
    )
  end

  def render_not_found(_exception)
    render_error(status: :not_found, code: "not_found", message: "対象のデータが見つかりません")
  end

  def render_bad_request(_exception)
    render_error(status: :bad_request, code: "bad_request", message: "リクエストの形式が正しくありません")
  end

  # 想定外のエラーは内部情報(例外メッセージやスタックトレース)を返さず、
  # 問い合わせ時にログと突き合わせられるよう request_id だけを返す。
  # 開発・テスト環境では原因を調べやすいよう、Rails標準のエラー画面・例外に任せる
  def render_internal_error(exception)
    raise exception if Rails.application.config.consider_all_requests_local

    Rails.logger.error("[#{exception.class}] #{exception.message}\n#{exception.backtrace&.first(10)&.join("\n")}")
    render_error(
      status: :internal_server_error,
      code: "internal_server_error",
      message: "サーバーでエラーが発生しました。時間をおいて再度お試しください",
      request_id: request.request_id
    )
  end
end
