module Api
  module V1
    class CustomersController < ApplicationController
      include Paginatable

      before_action :set_customer, only: %i[show update destroy]

      # GET /api/v1/customers?q=山田&agent_id=1&page=1&per_page=20
      def index
        customers = Customer.includes(:agent).search(params[:q])
        customers = customers.where(agent_id: params[:agent_id]) if params[:agent_id].present?
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

      def customer_params
        params.expect(customer: %i[agent_id name name_kana email phone budget_max desired_area note])
      end
    end
  end
end
