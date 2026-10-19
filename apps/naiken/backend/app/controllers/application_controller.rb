class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  # エラーレスポンスは { error: { code:, message:, details: } } の形式に統一する
  def render_error(status:, code:, message:, details: nil)
    body = { error: { code:, message:, details: }.compact }
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
end
