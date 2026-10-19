# 物件の住所を「都道府県」「市区町村」「町名・番地」に分け、エリアで絞り込めるようにする。
# 既存データは住所の文字列を分解して移行する(戻すときは連結する)
class SplitPropertyAddress < ActiveRecord::Migration[8.1]
  # 政令指定都市の区(例: 川崎市中原区)は「市+区」をひとまとまりの市区町村として扱う
  ADDRESS_PATTERN = /\A(?<prefecture>北海道|東京都|京都府|大阪府|.{2,3}県)(?<city>[^市]+市[^区]+区|.+?郡.+?[町村]|.+?[市区町村])(?<address_line>.*)\z/

  class MigrationProperty < ActiveRecord::Base
    self.table_name = "properties"
  end

  def up
    # 分解できない住所がある場合は、テーブルを変更する前に中断する
    parsed = MigrationProperty.pluck(:id, :address).to_h do |id, address|
      match = ADDRESS_PATTERN.match(address.to_s) || raise("住所を分解できません (properties.id=#{id}): #{address}")
      [ id, match.named_captures.transform_keys(&:to_sym) ]
    end

    add_column :properties, :prefecture, :string, after: :name, comment: "都道府県"
    add_column :properties, :city, :string, after: :prefecture, comment: "市区町村(政令指定都市は区まで)"
    rename_column :properties, :address, :address_line
    change_column_comment :properties, :address_line, from: nil, to: "町名・番地以降"
    MigrationProperty.reset_column_information

    parsed.each { |id, attrs| MigrationProperty.where(id:).update_all(attrs) }

    change_column_null :properties, :prefecture, false
    change_column_null :properties, :city, false
    add_index :properties, [ :prefecture, :city ]
  end

  def down
    remove_index :properties, [ :prefecture, :city ]
    execute "UPDATE properties SET address_line = CONCAT(prefecture, city, address_line)"
    change_column_comment :properties, :address_line, from: "町名・番地以降", to: nil
    rename_column :properties, :address_line, :address
    remove_column :properties, :city
    remove_column :properties, :prefecture
  end
end
