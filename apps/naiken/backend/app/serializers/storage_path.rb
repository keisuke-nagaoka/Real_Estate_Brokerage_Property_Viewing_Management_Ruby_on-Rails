# Active Storage のファイル(写真やサムネイル)を、画面から参照できるパスに変換する。
# Rails は /api/files/... で配信し、nginx はそれを /naiken/api/files/... で公開しているため、先頭にパスを補う
module StoragePath
  def self.for(attachable)
    path = Rails.application.routes.url_helpers.rails_storage_proxy_path(attachable, only_path: true)
    "#{Rails.configuration.x.public_path_prefix}#{path}"
  end
end
