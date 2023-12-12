class SessionsController < ApplicationController
  def new
  end

  def create
    #userをインスタンス変数にすることによってテストからアクセスできるようにする
    @user = User.find_by(email: params[:session][:email].downcase)
    if @user && @user.authenticate(params[:session][:password])
      if @user.activated?
        forwarding_url = session[:forwarding_url]
        #セッション固定（攻撃者が既に持っているセッションIDをユーザーに使わせるように仕向ける）を回避するためsessionをリセットする
        #session storeの中身を全て削除する（攻撃者が指定したidを使わせるようなプログラムが組み込まれている可能性がある）
        reset_session
        params[:session][:remember_me] == '1' ? remember(@user) : forget(@user)
        log_in @user
        redirect_to forwarding_url || @user
      else
        message = "Account not activated."
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      #flashはredirectの場合は、1回目だけ表示するがrenderの場合は新しいリクエストが呼ばれないためその次のページでも表示される
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url, status: :see_other
  end
end
