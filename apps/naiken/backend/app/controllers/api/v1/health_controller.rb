module Api
  module V1
    # /up はプロセスの死活のみを返すため、こちらはDB(ローカルMySQL / RDS)への接続まで確認する
    class HealthController < ApplicationController
      def show
        ActiveRecord::Base.connection.select_value("SELECT 1")
        render json: { status: "ok", database: "ok", environment: Rails.env, time: Time.current.iso8601 }
      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.error("[health] database check failed: #{e.class}: #{e.message}")
        render json: { status: "error", database: "unavailable" }, status: :service_unavailable
      end
    end
  end
end
