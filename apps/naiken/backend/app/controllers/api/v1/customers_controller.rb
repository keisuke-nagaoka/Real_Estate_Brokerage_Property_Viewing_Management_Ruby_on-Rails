module Api
  module V1
    class CustomersController < ApplicationController
      include Paginatable

      before_action :set_customer, only: %i[show update destroy change_status]

      # GET /api/v1/customers?q=山田&agent_id=1&status=inquiry,considering&page=1&per_page=20
      def index
        customers = Customer.includes(:agent).search(params[:q])
        customers = customers.where(agent_id: params[:agent_id]) if params[:agent_id].present?
        customers = customers.where(status: requested_statuses) if requested_statuses.any?
        customers, meta = paginate(customers.order(updated_at: :desc, id: :desc))

        render json: { data: customers.map { CustomerSerializer.render(it) }, meta: }
      end

      def show
        render json: { data: CustomerSerializer.render(@customer) }
      end

      def create
        customer = Customer.new(customer_params)
        if customer.save
          render json: { data: CustomerSerializer.render(customer) }, status: :created
        else
          render_validation_error(customer)
        end
      end

      def update
        if @customer.update(customer_params)
          render json: { data: CustomerSerializer.render(@customer) }
        else
          render_validation_error(@customer)
        end
      end

      # PATCH /api/v1/customers/:id/status  { "status": "considering" }
      # 対応ステータスは通常の更新では変えられず、遷移ルールを満たす場合のみこの操作で変更する
      def change_status
        if @customer.change_status(params.require(:status))
          render json: { data: CustomerSerializer.render(@customer), meta: { canceled_viewings_count: @customer.canceled_viewings_count } }
        else
          render_validation_error(@customer)
        end
      end

      def destroy
        if @customer.destroy
          head :no_content
        else
          render_validation_error(@customer)
        end
      end

      private

      def set_customer
        @customer = Customer.includes(:agent).find(params[:id])
      end

      # status=inquiry,considering のようにカンマ区切りで複数指定できる(未定義の値は無視する)
      def requested_statuses
        @requested_statuses ||= params[:status].to_s.split(",").map(&:strip) & Customer.statuses.keys
      end

      def customer_params
        params.expect(customer: %i[agent_id name name_kana email phone budget_max desired_area note])
      end
    end
  end
end
