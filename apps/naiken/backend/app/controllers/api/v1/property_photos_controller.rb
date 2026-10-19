module Api
  module V1
    # 物件写真の追加・削除。写真は multipart/form-data で photos[] として送る
    class PropertyPhotosController < ApplicationController
      before_action :set_property

      # POST /api/v1/properties/:property_id/photos
      def create
        files = Array(params.require(:photos))

        if @property.photos.attach(files)
          render json: { data: PropertySerializer.render(@property.reload) }, status: :created
        else
          render_validation_error(@property)
        end
      end

      # DELETE /api/v1/properties/:property_id/photos/:id
      def destroy
        @property.photos.find(params[:id]).purge
        render json: { data: PropertySerializer.render(@property.reload) }
      end

      private

      def set_property
        @property = Property.with_attached_photos.find(params[:property_id])
      end
    end
  end
end
