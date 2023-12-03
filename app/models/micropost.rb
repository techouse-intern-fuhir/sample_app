class Micropost < ApplicationRecord
  belongs_to :user
  #active_storageで生成した画像テーブルと結びつける(あたかもmicropostテーブルの一部のように扱う)
  #imageに対してvarientメソッドを使うことでリサイズしている(config/applicationでactive_storageにメソッドを接続)
  #この段階ではvarientメソッドを設定していて再びimageオブジェクトから呼ばれた時にリサイズする
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [500, 500]
  end
  #デフォルトの順序を指定するメソッド
  default_scope -> { order(created_at: :desc) }
  validates :user_id, presence: true
  #active_storage_validationsで対応
  validates :content, presence: true, length: { maximum: 140 }
  validates :image,   content_type: { in: %w[image/jpeg image/gif image/png],
                                      message: "must be a valid image format" },
                      size:         { less_than: 5.megabytes,
                                      message:   "should be less than 5MB" }
end
