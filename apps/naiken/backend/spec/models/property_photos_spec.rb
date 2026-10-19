require "rails_helper"

RSpec.describe Property, "写真", type: :model do
  let(:property) { create(:property) }

  def upload(name, content_type: nil)
    path = Rails.root.join("spec/fixtures/files", name)
    { io: File.open(path), filename: name, content_type: content_type || Marcel::MimeType.for(path) }
  end

  it "JPEG・PNG の写真を複数添付できる" do
    expect(property.photos.attach(upload("photo.jpg"), upload("photo.png"))).to be_truthy
    expect(property.reload.photos.count).to eq 2
  end

  it "形式はファイル名や送信された Content-Type ではなく、ファイルの中身で判定する" do
    # 中身はPDFだが、拡張子とContent-TypeはJPEGを装ったファイル
    disguised = upload("document.pdf", content_type: "image/jpeg").merge(filename: "photo.jpg")

    expect(property.photos.attach(disguised)).to be_falsey
    expect(property.errors.full_messages).to eq [ "写真「photo.jpg」はJPEG・PNG・WebP形式の画像にしてください" ]
  end

  it "5MBを超える写真は添付できない" do
    large = { io: StringIO.new("\xFF\xD8\xFF\xE0".b + ("\0" * 5.megabytes)), filename: "large.jpg", content_type: "image/jpeg" }

    expect(property.photos.attach(large)).to be_falsey
    expect(property.errors.full_messages).to eq [ "写真「large.jpg」は5MB以下にしてください" ]
  end

  it "1物件あたり10枚までしか添付できない" do
    property.photos.attach(Array.new(10) { upload("photo.jpg") })

    expect(property.photos.attach(upload("photo.jpg"))).to be_falsey
    expect(property.errors.full_messages).to eq [ "写真は10枚まで登録できます" ]
    expect(property.reload.photos.count).to eq 10
  end
end
