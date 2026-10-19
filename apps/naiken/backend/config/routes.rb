Rails.application.routes.draw do
  # コンテナのヘルスチェック用(アプリが起動していれば200)
  get "up" => "rails/health#show", as: :rails_health_check

  # nginxが /naiken/api/* を /api/* としてここに転送する
  namespace :api do
    namespace :v1 do
      resource :health, only: :show, controller: :health
      resources :agents, only: :index
      resources :customers, only: %i[index show create update destroy]
    end
  end
end
