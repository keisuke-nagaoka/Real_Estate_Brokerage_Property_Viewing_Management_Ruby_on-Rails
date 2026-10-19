require "rails_helper"

RSpec.describe "Api::V1::PropertyPhotos", type: :request do
  let(:property) { create(:property) }
  let(:photo) { fixture_file_upload("photo.jpg", "image/jpeg") }

  # 画面向けのURL(先頭に PUBLIC_PATH_PREFIX が付く)を、Rails へのリクエスト用のパスに戻す
  def rails_path(url)
    url.delete_prefix(Rails.configuration.x.public_path_prefix)
  end

  describe "POST /api/v1/properties/:property_id/photos" do
    it "写真を追加し、元画像とサムネイルのURLを返す" do
      post "/api/v1/properties/#{property.id}/photos", params: { photos: [ photo, fixture_file_upload("photo.png", "image/png") ] }

      expect(response).to have_http_status(:created)
      photos = response.parsed_body["data"]["photos"]
      expect(photos.size).to eq 2
      expect(photos.first).to include("filename" => "photo.jpg")
      expect(photos.first["url"]).to include("/api/files/representations/proxy/")
      expect(photos.first["thumbnail_url"]).to include("/api/files/representations/proxy/")
    end

    it "サムネイルのURLから、縮小した画像を取得できる" do
      post "/api/v1/properties/#{property.id}/photos", params: { photos: [ photo ] }
      thumbnail_url = response.parsed_body["data"]["photos"].first["thumbnail_url"]

      get rails_path(thumbnail_url)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "image/jpeg"
    end

    it "画像以外のファイルは422を返し、追加しない" do
      post "/api/v1/properties/#{property.id}/photos", params: { photos: [ fixture_file_upload("document.pdf", "application/pdf") ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["details"]["photos"]).to eq [ "写真「document.pdf」はJPEG・PNG・WebP形式の画像にしてください" ]
      expect(property.reload.photos).to be_empty
    end

    it "photos がない場合は400を返す" do
      post "/api/v1/properties/#{property.id}/photos", params: {}

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /api/v1/properties/:property_id/photos/:id" do
    it "写真を削除する" do
      property.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")
      attachment = property.photos.first

      delete "/api/v1/properties/#{property.id}/photos/#{attachment.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["photos"]).to be_empty
      expect(ActiveStorage::Attachment.exists?(attachment.id)).to be false
    end

    it "別の物件の写真は削除できず404を返す" do
      other = create(:property)
      other.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

      delete "/api/v1/properties/#{property.id}/photos/#{other.photos.first.id}"

      expect(response).to have_http_status(:not_found)
      expect(other.reload.photos.count).to eq 1
    end
  end

  describe "GET /api/v1/properties" do
    it "一覧にも写真のURLを含める" do
      property.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

      get "/api/v1/properties"

      expect(response.parsed_body["data"].first["photos"].first["thumbnail_url"]).to be_present
    end
  end
end
