require "test_helper"

# ヘルパー単位でテストを書く必要がある
class ApplicationHelperTest < ActionView::TestCase
    test "full title helper" do
      assert_equal "Ruby on Rails Tutorial Sample App", full_title
      assert_equal "Help | Ruby on Rails Tutorial Sample App", full_title("Help")
    end
  end