require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Naiken
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # DBにはUTCで保存し、アプリ上の表示・計算は日本時間で行う
    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :utc

    # 物件写真(Active Storage)は nginx が Rails に転送する /api/ 配下で配信する
    config.active_storage.routes_prefix = "/api/files"
    # リダイレクトだとプロキシ越しにホストやパスが崩れるため、Rails 経由で画像を返す(proxy モード)
    config.active_storage.resolve_model_to_route = :rails_storage_proxy
    # 画面から参照するURLの先頭に付けるパス(nginx で /naiken/ 配下に配信しているため)
    config.x.public_path_prefix = ENV.fetch("PUBLIC_PATH_PREFIX", "")

    # バリデーションエラーなどのメッセージを日本語で返す
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [ :ja, :en ]

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
