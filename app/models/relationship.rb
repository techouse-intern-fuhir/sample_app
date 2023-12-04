class Relationship < ApplicationRecord
  #普通belongs_toでは第一変数のモデル名_idを探してそのモデルのidと紐づけようとするが
  #この場合は別名を使うことによって能動、受動を場合分けしているのでforeignKeyを別名を
  #使っているためそれを元にUser.idに紐づけるように第一引数に書き込んでいる
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, presence: true
  validates :followed_id, presence: true
end
