class User < ApplicationRecord
  #dependent destroy→ユーザーの破壊と同時にマイクロポストも破壊
  has_many :microposts, dependent: :destroy

  #関連付けとはあるテーブルから関係性のあるテーブルに対して直接よびだしたり、その関係性を明示した状態でレコードできること
  #relationshipのfollower_idと関連付け(relationの別名としてactive_relationshipを使用)
  #relationに対して別名を使う理由としては多対多の相手同士が同じモデルであるため、それぞれどの方向で呼び出しているのかを明確にするため
  #foeign_key→一般的にリレーションを作る時には自身のテーブルの名前からsをとりそれに_idをつけるがrelationテーブルでは親がどちらもuserテーブル
    #であるためその親を表すkey名がそれぞれfollower_id, followed_idとなっていたから
  #class_name→リレーション相手となるモデルのクラス名を記述、普通クラス名は指定されたリレーション相手のテーブルの名前からモデル名が推測される
  has_many :active_relationships, class_name: "Relationship",
                                 foreign_key: "follower_id",
                                 dependent: :destroy
  
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy

  #関連付けたactive_relationships(follower_id)を通してfollowing(user)を取得(relationshipモデルのfollowerメソッドを使用)
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  
  #仮想remember_tokenを作成→cookieのremember_tokenとdbのremember_digestを橋渡し
  #仮想activation_tokenを作成→mail内のactivation_tokenとdbのactivation_digestの橋渡し
  #仮想reset_token→activation_tokenと同じ
  attr_accessor :remember_token, :activation_token, :reset_token

  #メソッド参照→メソッドを探索して実行する
  #update_columnsでは実行されない
  before_save :downcase_email
  before_create :create_activation_digest
  validates :name, presence: true,
                   length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    # uniqueness: { case_sensitive: false }
                    uniqueness: true

  #できるようになること→セキュアにハッシュ化したパスワードをpassword_digestに保存できるようになる
                 #二つの仮想属性password, password_confimationが使えるようになる
                 #authenticateメソッドが使えるようになる(内部でパスワードを比較している)
  #仮想属性→データベース上には存在していないがモデル上には存在する属性のこと
  has_secure_password

  validates :password, presence: true,
                       length: { minimum: 8 },
                       allow_nil: true
  
  #渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # return a random token
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  #永続的セッションのためにユーザーをデータベースに記憶する
  #update_attribute→dbの中身の変更＋dbと結びついたインスタンス変更
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
    remember_digest
  end

  #渡されたトークンがダイジェストと一致したらtrueを返す
  #remember_digest→self.remember_digest(UserModel)
  def authenticated?(attribute, token)
    #send→引数名の関数を呼び出している(レシーバーが省略されるとself)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    #BCrypt::Password.new(remember_digest).is_password?(remember_token)→remember_tokenに対して比較演算子が再定義されている
    BCrypt::Password.new(digest).is_password?(token)
  end

  #ユーザーのログイン情報を破棄する
  #selfが省略されている
  def forget
    #validationは行われない
    update_attribute(:remember_digest, nil)
  end

  #セッションハイジャック防止のためにセッショントークンを返す
  #この記憶ダイジェストを再利用しているのは単に利便性のため
  #remember_digest→self.remember_digest(UserModel)
  def session_token
    remember_digest || remember
  end

  #アカウントを有効にする
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  #有効化用のメールを送信する
  def send_activation_email
    #deliver　queueに追加して今すぐメールが飛ばされる
    UserMailer.account_activation(self).deliver_now
  end

  #パスワード再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    #コールバックが呼び出されない、validationも呼び出さない
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  #パスワード再設定のメールを送信する
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  #パスワード再設定の期限が切れている場合はtrueを返す
  def password_reset_expired?
    reset_sent_at < 2.hour.ago
  end

  #試作feedの定義
  #Micropost.where("user_id = ?", id)→ micropostsと同じ意味
  #users画面でmicropostを利用するため
  def feed
    #?があることで、SQLクエリに代入する前にidがエスケープされるため、SQLインジェクション（SQL Injection）と呼ばれる深刻なセキュリティホールを回避できる
    # Micropost.where("user_id IN (?) OR user_id = ?", following_ids, id)
    #集合のロジックをrailsではなくデータベース側で処理することで効率が高まる
    following_ids = "SELECT followed_id FROM relationships
                     WHERE  follower_id = :user_id"

    #パーシャル内でmiropost.user, micropost.userなどでここにクエリをデータベースに送信してしまうため
    #最初に一度に読んでいる
    #親子関係のデータリソースをまとめてDBから取得できるメソッド
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
             .includes(:user, image_attachment: :blob)

    # part_of_feed = "followers_users.id = :id or microposts.user_id = :id"
    part_of_feed = "relationships.follower_id = :id or microposts.user_id = :id"
    #micropostに対してuser.followersを発火することでmicropostテーブルに対してuser-relationships-userを結合させている
    #userがふたつ重複してしまうため、ふたつめのuserはメソッド名と結合させて名前を作っている
    #つまりmicropost-user(フォローされている側)-relationships-followers_users(フォローしている)
    Micropost.left_outer_joins(user: :followers)
             .where(part_of_feed, { id: id }).distinct
             .includes(:user, image_attachment: :blob)
  end

  #ユーザーをフォローする
  def follow(other_user)
    following << other_user unless self == other_user
  end

  #ユーザーをフォロー解除する
  def unfollow(other_user)
    following.delete(other_user)
  end

  #現在のユーザーが他のユーザーをフォローしていればtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end

  private

    #メールアドレスを全て小文字にする
    def downcase_email
      email.downcase!
    end

    #有効化トークンとダイジェストを作成および代入する
    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end

end
