class CreateViewings < ActiveRecord::Migration[8.1]
  def change
    create_table :viewings do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, null: false, default: "scheduled", comment: "scheduled: 予定 / completed: 実施済み / canceled: キャンセル"
      t.text :note

      t.timestamps
    end
    # 担当者ごとの時間帯の重複チェックに使う
    add_index :viewings, [ :agent_id, :status, :starts_at ]
    add_index :viewings, :starts_at
  end
end
