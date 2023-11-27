class ApplicationController < ActionController::Base
  def hello
    render html: "hello, world!"
  end
  include SessionsHelper
end

#すべてのviewから使える
#controllerから使えるようにするためには使いたいcontrollerの中でincludeしなければならない
