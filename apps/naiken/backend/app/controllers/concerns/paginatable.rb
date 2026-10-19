# page / per_page パラメータによるページネーション
module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  private

  def paginate(scope)
    per_page = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
    page = [ params.fetch(:page, 1).to_i, 1 ].max
    total_count = scope.count

    records = scope.limit(per_page).offset((page - 1) * per_page)
    meta = { page:, per_page:, total_count:, total_pages: (total_count.to_f / per_page).ceil }
    [ records, meta ]
  end
end
