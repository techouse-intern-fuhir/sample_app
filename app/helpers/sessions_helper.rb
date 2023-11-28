module SessionsHelper

  #渡されたユーザーでログインする
  def log_in(user)
    session[:user_id] = user.id
    #セッションリプレス攻撃から保護する
    #user_idに加えてもう1つミュータブルなデータポイントを追加し、両方が有効な場合にのみユーザーを認証するように
    session[:session_token] = user.session_token
  end
  
  #永続的セッションのためにユーザーをデータベースに記憶する
  def remember(user)
    user.remember
    cookies.permanent.encrypted[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # 記憶トークンcookieに対応するユーザーを返す
  def current_user
    if (user_id = session[:user_id])
      user = User.find_by(id: user_id)
      # user_idに加えてもう1つミュータブルなデータポイントを追加し、両方が有効な場合にのみユーザーを認証するように
      if user && session[:session_token] == user.remember_digest
        @current_user = user
      end
    elsif (user_id = cookies.encrypted[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end
  
  #渡されたユーザーがカレントユーザーであればtrueを返す
  def current_user?(user)
    user && user == current_user
  end
  
  #if user loged in then true, if other false, is sent
  def logged_in?
    !current_user.nil?
  end

  #永続的セッションを破壊する
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  #現在のユーザーをログアウト
  def log_out
    forget(current_user)
    reset_session
    @current_user = nil
  end

  #アクセスしようとしたURL保存する
  def store_location
    #ログインしていないユーザーがフォームから送信した場合は、転送先のURLを保存しないようにgetメソッドだけを指定
    session[:forwarding_url] = request.original_url if request.get?
  end

end
