class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end
    add_index :agents, :email, unique: true
  end
end
