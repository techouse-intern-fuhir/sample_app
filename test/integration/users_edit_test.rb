require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest
  
  def setup 
    @user = users(:michael)
  end

  test "unsuccessful edit" do
    #edit, updateのbeforeフィルターを通すためにloginさせる
    get edit_user_path(@user)
    log_in_as(@user)

    #redirect先をチェック
    assert_redirected_to edit_user_url(@user)
    patch user_path(@user), params: { user: { name: "", 
                                              email: "foo@invalid",
                                              password: "foo",
                                              password_confirmation: "bar"
                                            }}
    assert_template 'users/edit'
    assert_select "div", "The form contains 4 errors."
  end

  test "successful edit with friendly forwarding" do
    log_in_as(@user)
    get edit_user_path(@user)
    name = "Foo Bar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: { name: name,
                                              email: email,
                                              password: "",
                                              password_confirmation: ""}}
    
    #TDD
    assert_not flash.empty?
    assert_redirected_to @user

    #@user.reload→最新のユーザー情報をデータベースから呼び出す
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email

    assert_not session[:forwarwding_url]
  end
end
