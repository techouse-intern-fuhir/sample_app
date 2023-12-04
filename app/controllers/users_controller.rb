class UsersController < ApplicationController

  #何らかの処理が実行される直前に特定のメソッドを実行する
  #beforeフィルターは基本コントローラー内の全てのアクションに適応されているので適切な:onlyオプションを渡すことで
  #:edit, :updateにしか適応されないようにしている
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user, only: :destroy

  def index
    # :page→値がページ版後のハッシュを引数で受け取る
    # params[:page]→will_paginateによって自動的に渡される(nil→1)
    # paginate→:pageパラメーターに基づいて、データベースから一塊のデータを受け取る
    @users = User.where(activated: true).paginate(page: params[:page])
  end

  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
    redirect_to root_url and return unless @user.activated?
  end

  def new
    @user = User.new
  end

  def create
    #before_createでactivation_token生成
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:success] = "Please check your email to activate your account"
      redirect_to root_url
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url, status: :see_other
  end

  def following
    @title = "Following"
    @user = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render "show_follow"
  end

  def followers
    @title = "Followers"
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render "show_follow"
  end

  private

    def user_params
      #paramsの中から許されている要素だけを取り出して改めてハッシュとして返している
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

    #beforeフィルタ

    #login情報とurlが同一か確認
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url, status: :see_other) unless current_user?(@user)
    end

    #管理者かどうか確認
    def admin_user
      redirect_to(root_url, status: :see_other) unless current_user.admin?
    end

end
