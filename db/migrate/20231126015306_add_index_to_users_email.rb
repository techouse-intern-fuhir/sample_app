class AddIndexToUsersEmail < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :email, unique: true
  end
end

# userのemailにインデックスそのインデックスに対して一意性を付与している→ダブルクリックによる重複防止