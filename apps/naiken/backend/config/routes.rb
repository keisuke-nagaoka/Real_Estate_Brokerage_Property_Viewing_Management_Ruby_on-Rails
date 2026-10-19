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
      resources :properties, only: %i[index show create update destroy] do
        get :areas, on: :collection
        resources :photos, only: %i[create destroy], controller: :property_photos
      end
      resources :viewings, only: %i[index show create update] do
        member do
          patch :complete
          patch :cancel
        end
      end
    end
  end

  # どのルートにも一致しないURLは、HTMLではなくJSONの404を返す。
  # Active Storage のルート(写真の配信)はこの後ろに追加されるため、写真のパスは除外する
  match "*unmatched", to: "application#route_not_found", via: :all,
                      constraints: ->(request) { !request.path.start_with?("#{ActiveStorage.routes_prefix}/") }
end
