require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should sign in" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    assert_redirected_to root_url
  end

  test "should sign out" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    delete session_url
    assert_redirected_to root_url
  end
end
