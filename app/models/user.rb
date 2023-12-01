class User < ApplicationRecord
  #dependent destroy→ユーザーの破壊と同時にマイクロポストも破壊
  has_many :microposts, dependent: :destroy
  #仮想remember_tokenを作成
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
    #BCrypt::Password.new(remember_digest).is_password?(remember_token)→比較演算子が再定義されている
    BCrypt::Password.new(digest).is_password?(token)
  end

  #ユーザーのログイン情報を破棄する
  #selfが省略されている
  def forget
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
    #コールバックが呼び出されない
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
    Micropost.where("user_id = ?", id)
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
