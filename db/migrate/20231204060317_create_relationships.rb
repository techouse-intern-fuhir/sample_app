class CreateRelationships < ActiveRecord::Migration[7.0]
  def change
    create_table :relationships do |t|
      t.integer :follower_id
      t.integer :followed_id

      t.timestamps
    end
    add_index :relationships, :follower_id
    add_index :relationships, :followed_id
    #複合キーを作りfollower_idとfollowed_idの組み合わせが重複しないようにしている
    add_index :relationships, [:follower_id, :followed_id], unique: true
  end
end
