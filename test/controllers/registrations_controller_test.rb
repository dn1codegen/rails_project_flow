require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get new_registration_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count", 1) do
      post registration_url, params: {
        user: {
          name: "Charlie",
          email: "charlie@example.com",
          bio: "Designer",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
  end

  test "signed in user is redirected from registration page" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    get new_registration_url
    assert_redirected_to root_url
  end
end
