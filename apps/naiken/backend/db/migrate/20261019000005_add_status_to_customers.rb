class AddStatusToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :status, :string, null: false, default: "inquiry",
               comment: "対応ステータス(inquiry: 問い合わせ / viewing_scheduled: 内見予定 / considering: 検討中 / contracted: 成約 / lost: 失注)",
               after: :agent_id
    add_index :customers, :status
  end
end
