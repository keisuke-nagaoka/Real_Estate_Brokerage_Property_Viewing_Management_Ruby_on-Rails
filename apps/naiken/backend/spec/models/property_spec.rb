require "rails_helper"

RSpec.describe Property, type: :model do
  describe "バリデーション" do
    it "ファクトリのデータは有効である" do
      expect(build(:property)).to be_valid
    end

    it "物件名・住所・価格は必須である" do
      property = build(:property, name: "", address: "", price: nil)

      expect(property).to be_invalid
      expect(property.errors.full_messages).to include("物件名を入力してください", "住所を入力してください", "価格を入力してください")
    end

    it "価格が未入力の場合は「入力してください」のエラーだけを返す" do
      property = build(:property, price: nil)

      expect(property).to be_invalid
      expect(property.errors[:price]).to eq [ "を入力してください" ]
    end

    it "価格は1万円以上100億円以下の整数のみ許可する" do
      expect(build(:property, price: 1)).to be_valid
      expect(build(:property, price: 1_000_000)).to be_valid
      expect(build(:property, price: 0)).to be_invalid
      expect(build(:property, price: 1_000_001)).to be_invalid
    end

    it "間取りは「3LDK」「1K」「ワンルーム」などの形式のみ許可する" do
      %w[1R 1K 2DK 3LDK 4SLDK ワンルーム].each do |layout|
        expect(build(:property, layout:)).to be_valid, "#{layout} は有効であるべき"
      end
      expect(build(:property, layout: "広め")).to be_invalid
    end

    it "築年は1900年から3年後までを許可する" do
      expect(build(:property, built_year: 1900)).to be_valid
      expect(build(:property, built_year: Date.current.year + 3)).to be_valid
      expect(build(:property, built_year: 1899)).to be_invalid

      property = build(:property, built_year: Date.current.year + 4)
      expect(property).to be_invalid
      expect(property.errors[:built_year]).to eq [ "は3年後までの年を入力してください" ]
    end

    it "駅徒歩は0〜120分の整数のみ許可する" do
      expect(build(:property, walk_minutes: 0)).to be_valid
      expect(build(:property, walk_minutes: 121)).to be_invalid
    end

    it "掲載状況は定義済みの値のみ許可する" do
      property = build(:property, status: "unknown")

      expect(property).to be_invalid
      expect(property.errors[:status]).to be_present
    end
  end

  describe "正規化" do
    it "全角・小文字の間取りを半角大文字にそろえる" do
      expect(build(:property, layout: "３ｌｄｋ").layout).to eq "3LDK"
    end

    it "空文字の任意項目はnilにする" do
      property = build(:property, layout: "", nearest_station: " ", note: "")

      expect(property.layout).to be_nil
      expect(property.nearest_station).to be_nil
      expect(property.note).to be_nil
    end
  end

  describe ".search" do
    let!(:setagaya) { create(:property, name: "パークハウス世田谷", address: "東京都世田谷区", nearest_station: "千歳船橋") }
    let!(:meguro) { create(:property, name: "プラウド目黒", address: "東京都目黒区", nearest_station: "武蔵小山") }

    it "物件名・住所・最寄り駅の部分一致で検索できる" do
      expect(described_class.search("パークハウス")).to contain_exactly(setagaya)
      expect(described_class.search("目黒区")).to contain_exactly(meguro)
      expect(described_class.search("武蔵小山")).to contain_exactly(meguro)
    end
  end

  describe ".price_between" do
    let!(:cheap) { create(:property, price: 3000) }
    let!(:middle) { create(:property, price: 5000) }
    let!(:expensive) { create(:property, price: 8000) }

    it "下限・上限を含む範囲で絞り込める" do
      expect(described_class.price_between(3000, 5000)).to contain_exactly(cheap, middle)
    end

    it "片方だけの指定もできる" do
      expect(described_class.price_between(5000, nil)).to contain_exactly(middle, expensive)
      expect(described_class.price_between(nil, 4000)).to contain_exactly(cheap)
    end
  end
end
