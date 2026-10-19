class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :name, null: false
      t.string :name_kana, null: false
      t.string :email
      t.string :phone
      t.integer :budget_max, comment: "予算上限(万円)"
      t.string :desired_area, comment: "希望エリア"
      t.text :note

      t.timestamps
    end
    add_index :customers, :name_kana
  end
end
