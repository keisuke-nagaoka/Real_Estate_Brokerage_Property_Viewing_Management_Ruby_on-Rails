module Api
  module V1
    class PropertiesController < ApplicationController
      include Paginatable

      before_action :set_property, only: %i[show update destroy]

      # GET /api/v1/properties?q=桜丘&prefecture=東京都&city=世田谷区&status=available&price_min=3000&price_max=6000&page=1
      def index
        properties = Property.with_attached_photos
                             .search(params[:q])
                             .in_area(params[:prefecture], params[:city])
                             .price_between(params[:price_min], params[:price_max])
        properties = properties.where(status: params[:status]) if Property.statuses.key?(params[:status])
        properties, meta = paginate(properties.order(updated_at: :desc, id: :desc))

        render json: { data: properties.map { PropertySerializer.render(it) }, meta: }
      end

      # GET /api/v1/properties/areas  絞り込みの選択肢として、物件があるエリアと件数を返す
      def areas
        render json: { data: Property.areas }
      end

      def show
        render json: { data: PropertySerializer.render(@property) }
      end

      def create
        property = Property.new(property_params)
        if property.save
          render json: { data: PropertySerializer.render(property) }, status: :created
        else
          render_validation_error(property)
        end
      end

      def update
        if @property.update(property_params)
          render json: { data: PropertySerializer.render(@property) }
        else
          render_validation_error(@property)
        end
      end

      def destroy
        if @property.destroy
          head :no_content
        else
          render_validation_error(@property)
        end
      end

      private

      def set_property
        @property = Property.with_attached_photos.find(params[:id])
      end

      def property_params
        params.expect(property: %i[name prefecture city address_line price layout floor_area built_year nearest_station walk_minutes status note])
      end
    end
  end
end
