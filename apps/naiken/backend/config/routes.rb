Rails.application.routes.draw do
  # コンテナのヘルスチェック用(アプリが起動していれば200)
  get "up" => "rails/health#show", as: :rails_health_check

  # nginxが /naiken/api/* を /api/* としてここに転送する
  namespace :api do
    namespace :v1 do
      resource :health, only: :show, controller: :health
    end
  end
end
