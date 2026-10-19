require "rails_helper"

RSpec.describe Property, type: :model do
  describe "バリデーション" do
    it "ファクトリのデータは有効である" do
      expect(build(:property)).to be_valid
    end

    it "物件名・住所(都道府県・市区町村・町名番地)・価格は必須である" do
      property = build(:property, name: "", prefecture: "", city: "", address_line: "", price: nil)

      expect(property).to be_invalid
      expect(property.errors.full_messages).to contain_exactly(
        "物件名を入力してください", "都道府県を入力してください", "市区町村を入力してください", "町名・番地を入力してください", "価格を入力してください"
      )
    end

    it "都道府県は47都道府県のいずれかでなければならない" do
      expect(build(:property, prefecture: "北海道")).to be_valid
      expect(build(:property, prefecture: "沖縄県")).to be_valid

      property = build(:property, prefecture: "東京")
      expect(property).to be_invalid
      expect(property.errors.full_messages).to eq [ "都道府県は一覧にありません" ]
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

  describe "#address" do
    it "都道府県・市区町村・町名番地をつなげた住所を返す" do
      property = build(:property, prefecture: "神奈川県", city: "川崎市中原区", address_line: "小杉町1丁目")

      expect(property.address).to eq "神奈川県川崎市中原区小杉町1丁目"
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
    let!(:setagaya) { create(:property, name: "パークハウス世田谷", city: "世田谷区", address_line: "桜丘3丁目", nearest_station: "千歳船橋") }
    let!(:meguro) { create(:property, name: "プラウド目黒", city: "目黒区", address_line: "目黒本町5丁目", nearest_station: "武蔵小山") }

    it "物件名・住所・最寄り駅の部分一致で検索できる" do
      expect(described_class.search("パークハウス")).to contain_exactly(setagaya)
      expect(described_class.search("目黒本町")).to contain_exactly(meguro)
      expect(described_class.search("武蔵小山")).to contain_exactly(meguro)
    end

    it "住所は都道府県・市区町村・町名番地の区切りをまたいで検索できる" do
      expect(described_class.search("世田谷区桜丘")).to contain_exactly(setagaya)
      expect(described_class.search("東京都目黒区")).to contain_exactly(meguro)
    end
  end

  describe ".in_area" do
    let!(:setagaya) { create(:property, prefecture: "東京都", city: "世田谷区") }
    let!(:minato) { create(:property, prefecture: "東京都", city: "港区") }
    let!(:kawasaki) { create(:property, prefecture: "神奈川県", city: "川崎市中原区") }

    it "都道府県で絞り込める" do
      expect(described_class.in_area("東京都")).to contain_exactly(setagaya, minato)
    end

    it "都道府県と市区町村で絞り込める" do
      expect(described_class.in_area("東京都", "港区")).to contain_exactly(minato)
    end

    it "指定がない場合は絞り込まない" do
      expect(described_class.in_area(nil, nil)).to contain_exactly(setagaya, minato, kawasaki)
    end
  end

  describe ".areas" do
    it "物件があるエリアを都道府県コード順・市区町村名順に、件数付きで返す" do
      create_list(:property, 2, prefecture: "東京都", city: "世田谷区")
      create(:property, prefecture: "東京都", city: "港区")
      create(:property, prefecture: "神奈川県", city: "川崎市中原区")
      create(:property, prefecture: "埼玉県", city: "さいたま市浦和区")

      expect(described_class.areas).to eq [
        { prefecture: "埼玉県", count: 1, cities: [ { name: "さいたま市浦和区", count: 1 } ] },
        { prefecture: "東京都", count: 3, cities: [ { name: "世田谷区", count: 2 }, { name: "港区", count: 1 } ] },
        { prefecture: "神奈川県", count: 1, cities: [ { name: "川崎市中原区", count: 1 } ] }
      ]
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
