class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :address, null: false
      t.integer :price, null: false, comment: "価格(万円)"
      t.string :layout, comment: "間取り(例: 3LDK)"
      t.decimal :floor_area, precision: 7, scale: 2, comment: "専有面積(㎡)"
      t.integer :built_year, comment: "築年(西暦)"
      t.string :nearest_station
      t.integer :walk_minutes, comment: "駅徒歩(分)"
      t.string :status, null: false, default: "available", comment: "掲載状況(available: 掲載中 / closed: 掲載終了)"
      t.text :note

      t.timestamps
    end
    add_index :properties, [ :status, :price ]
  end
end
