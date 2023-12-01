class StaticPagesController < ApplicationController

  def home
    if logged_in?
      #投稿用オブジェクト
      @micropost = current_user.microposts.build

      #一覧用
      @feed_items = current_user.feed.paginate(page: params[:page])
    end
  end

  def help
  end

  def about
  end

  def contact
  end
  
end
