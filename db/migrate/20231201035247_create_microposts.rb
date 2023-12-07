class CreateMicroposts < ActiveRecord::Migration[7.0]
  def change
    create_table :microposts do |t|
      t.text :content
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    #二つのカラムにインデックスを付与
    #複合キーを作ることによって二つのキーを合わせて絞り込みをする時に高速で見つけ出してくれる
    add_index :microposts, [:user_id, :created_at]
  end
end
