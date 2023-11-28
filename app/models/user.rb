class User < ApplicationRecord
  #仮想remember_tokenを作成
  attr_accessor :remember_token
  before_save { email.downcase! }
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
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    #BCrypt::Password.new(remember_digest).is_password?(remember_token)→比較演算子が再定義されている
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  #ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  #セッションハイジャック防止のためにセッショントークンを返す
  #この記憶ダイジェストを再利用しているのは単に利便性のため
  #remember_digest→self.remember_digest(UserModel)
  def session_token
    remember_digest || remember
  end

end
