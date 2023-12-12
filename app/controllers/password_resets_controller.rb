class PasswordResetsController < ApplicationController
  before_action :get_user, only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def new
  end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash.now[:danger] = "Email address not found"
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    #password属性は基本空欄でもvalid?でtrueになってしまうためそれを回避してかつ、errorsに正しいエラーを含める
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit', status: :unprocessable_entity
    elsif @user.update(user_params)
      #セッションを盗まれたことに気づいたユーザーが即座にパスワードをリセットする場合を想定してセッションを破壊
      #ハイジャックされたセッションをこの操作で自動的に失効させる
      @user.forget
      #パスワードの再設定に成功したらブラウザバックでパスワード更新をできないようにする
      @user.update_attribute(:reset_digest, nil)
      reset_session
      log_in @user
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  private

  def user_params
    #password, comfirmation_passwordの属性精査
    params.require(:user).permit(:password, :password_confirmation)
  end
    
  def get_user
    #アクションに渡される前にもう一つ下のフィルタのvalid_userに渡される
    @user = User.find_by(email: params[:email])
  end

  # 正しいユーザーかどうか確認する
  def valid_user
    unless (@user && @user.activated? && @user.authenticated?(:reset, params[:id]))
      redirect_to root_url
    end
  end

  #トークンが期限切れかどうか確認する
  def check_expiration
    #期限切れかどうかを確認するインスタンスメソッド
    if @user.password_reset_expired?
      flash[:danger] = "Password reset has expired"
      redirect_to new_password_reset_url
    end
  end

end
