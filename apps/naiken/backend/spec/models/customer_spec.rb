require "rails_helper"

RSpec.describe Customer, type: :model do
  describe "バリデーション" do
    it "ファクトリのデータは有効である" do
      expect(build(:customer)).to be_valid
    end

    it "氏名・フリガナ・担当者は必須である" do
      customer = build(:customer, name: "", name_kana: "", agent: nil)

      expect(customer).to be_invalid
      expect(customer.errors.full_messages).to include("氏名を入力してください", "フリガナを入力してください", "担当者を入力してください")
    end

    it "フリガナは全角カタカナのみ許可する" do
      expect(build(:customer, name_kana: "ヤマダ タロウ")).to be_valid
      expect(build(:customer, name_kana: "やまだ たろう")).to be_invalid
    end

    it "電話番号は日本の電話番号の形式のみ許可する" do
      expect(build(:customer, phone: "03-1234-5678")).to be_valid
      expect(build(:customer, phone: "09012345678")).to be_valid
      expect(build(:customer, phone: "abc")).to be_invalid
    end

    it "予算上限は正の整数のみ許可する" do
      expect(build(:customer, budget_max: nil)).to be_valid
      expect(build(:customer, budget_max: 0)).to be_invalid
      expect(build(:customer, budget_max: 1.5)).to be_invalid
    end
  end

  describe "正規化" do
    it "メールアドレスを小文字にし、前後の空白を除く" do
      expect(build(:customer, email: " Yamada@Example.COM ").email).to eq "yamada@example.com"
    end

    it "全角の電話番号を半角にする" do
      expect(build(:customer, phone: "０９０－１２３４－５６７８").phone).to eq "090-1234-5678"
    end

    it "空文字の任意項目はnilにする" do
      customer = build(:customer, email: "", phone: "", desired_area: " ", note: "")

      expect(customer.email).to be_nil
      expect(customer.phone).to be_nil
      expect(customer.desired_area).to be_nil
      expect(customer.note).to be_nil
    end
  end

  describe ".search" do
    let!(:yamada) { create(:customer, name: "山田 太郎", name_kana: "ヤマダ タロウ", email: "yamada@example.com", phone: "090-1111-2222") }
    let!(:tanaka) { create(:customer, name: "田中 花子", name_kana: "タナカ ハナコ", email: "tanaka@example.com", phone: "080-3333-4444") }

    it "氏名・フリガナ・メールアドレス・電話番号の部分一致で検索できる" do
      expect(described_class.search("山田")).to contain_exactly(yamada)
      expect(described_class.search("ハナコ")).to contain_exactly(tanaka)
      expect(described_class.search("tanaka@")).to contain_exactly(tanaka)
      expect(described_class.search("1111")).to contain_exactly(yamada)
    end

    it "キーワードが空の場合は全件を返す" do
      expect(described_class.search("")).to contain_exactly(yamada, tanaka)
    end

    it "LIKEのワイルドカード文字はエスケープされる" do
      expect(described_class.search("%")).to be_empty
    end
  end
end
