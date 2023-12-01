class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: :destroy

  def create
    @micropost = current_user.microposts.build(micropost_params)
    #ここで紐付かれたあたidと一緒に画像が画像データベースに保存される
    @micropost.image.attach(params[:micropost][:image])
    if @micropost.save
      flash[:success] = "Micropost created!"
      redirect_to root_url
    else
      @feed_items = current_user.feed.paginate(page: params[:page])  
      #renderメソッドはファイルパスとして使っているためコントローラーのアクションは踏まずに直接viewを呼び出している
      render 'static_pages/home', status: :unprocessable_entity
    end
  end

  def destroy
    @micropost.destroy
    flash[:success] = "Micropost deleted"
    #エッジケース（滅多に怒らないエラー）に備えとく
    # if request.referrer.nil?
    #   redirect_to root_url, status: :see_other
    # else
    #   #常に元のページを指すリファラーをリダイレクト先に設定
    #   redirect_to request.referrer, status: :see_other
    # end
    #シュガーシンタックス
    redirect_back_or_to(root_url, status: :see_other)
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content, :image)
    end

    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url, status: :see_other if @micropost.nil?
    end
end
