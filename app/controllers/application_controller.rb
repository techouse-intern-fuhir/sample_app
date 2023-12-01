class ApplicationController < ActionController::Base
  def hello
    render html: "hello, world!"
  end
  include SessionsHelper

  #ユーザーのログインを確認する
  #deleteテストでも使われるためため整合性をあわせるためのstatus: :see_other
  def logged_in_user
    unless logged_in?
      #フレンドリーフォワーディング
      store_location
      flash[:danger] = "Please log in."
      redirect_to login_url, status: :see_other
    end
  end

end

#すべてのviewから使える
#controllerから使えるようにするためには使いたいcontrollerの中でincludeしなければならない
