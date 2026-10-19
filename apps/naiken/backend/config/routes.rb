Rails.application.routes.draw do
  # コンテナのヘルスチェック用(アプリが起動していれば200)
  get "up" => "rails/health#show", as: :rails_health_check

  # nginxが /naiken/api/* を /api/* としてここに転送する
  namespace :api do
    namespace :v1 do
      resource :health, only: :show, controller: :health
      resources :agents, only: :index
      resources :customers, only: %i[index show create update destroy] do
        patch :status, on: :member, action: :change_status
      end
      resources :properties, only: %i[index show create update destroy]
      resources :viewings, only: %i[index show create update] do
        member do
          patch :complete
          patch :cancel
        end
      end
    end
  end

  # どのルートにも一致しないURLは、HTMLではなくJSONの404を返す
  match "*unmatched", to: "application#route_not_found", via: :all
end
