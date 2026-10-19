module Api
  module V1
    class ViewingsController < ApplicationController
      include Paginatable

      before_action :set_viewing, only: %i[show update complete cancel]

      # GET /api/v1/viewings?from=2026-10-01&to=2026-10-31&agent_id=1&customer_id=1&property_id=1&status=scheduled
      def index
        viewings = Viewing.includes(:customer, :property, :agent)
        viewings = viewings.starts_on_or_after(parse_date(:from)) if params[:from].present?
        viewings = viewings.starts_on_or_before(parse_date(:to)) if params[:to].present?
        %i[agent_id customer_id property_id].each do |key|
          viewings = viewings.where(key => params[key]) if params[key].present?
        end
        viewings = viewings.where(status: params[:status]) if Viewing.statuses.key?(params[:status])

        # 過去の予定を見るときは新しい順、それ以外は近い順に並べる
        direction = params[:order] == "desc" ? :desc : :asc
        viewings, meta = paginate(viewings.order(starts_at: direction, id: direction))

        render json: { data: viewings.map { ViewingSerializer.render(it) }, meta: }
      end

      def show
        render json: { data: ViewingSerializer.render(@viewing) }
      end

      def create
        viewing = Viewing.new(viewing_params)
        if viewing.save_with_agent_lock
          render json: { data: ViewingSerializer.render(viewing) }, status: :created
        else
          render_validation_error(viewing)
        end
      end

      def update
        @viewing.assign_attributes(viewing_params)
        if @viewing.save_with_agent_lock
          render json: { data: ViewingSerializer.render(@viewing) }
        else
          render_validation_error(@viewing)
        end
      end

      # ステータスは通常の更新では変えられず、以下の操作でのみ遷移させる(予定 → 実施済み / キャンセル)
      def complete
        if @viewing.complete
          render json: { data: ViewingSerializer.render(@viewing) }
        else
          render_validation_error(@viewing)
        end
      end

      def cancel
        if @viewing.cancel
          render json: { data: ViewingSerializer.render(@viewing) }
        else
          render_validation_error(@viewing)
        end
      end

      private

      def set_viewing
        @viewing = Viewing.includes(:customer, :property, :agent).find(params[:id])
      end

      def viewing_params
        params.expect(viewing: %i[customer_id property_id agent_id starts_at ends_at note])
      end

      def parse_date(key)
        Date.iso8601(params[key])
      rescue Date::Error
        raise ActionController::BadRequest, "#{key} must be YYYY-MM-DD"
      end
    end
  end
end
