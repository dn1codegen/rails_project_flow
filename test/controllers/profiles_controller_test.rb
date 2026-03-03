require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { session: { email: @user.email, password: "password123" } }
  end

  test "should get show" do
    get profile_url
    assert_response :success
    assert_select ".profile-project-list", count: 1
    assert_select ".profile-project-list .project-list-block-count", text: "1", count: 1
    assert_select ".profile-project-list .project-list-row", text: /Inventory Service/, count: 1
    assert_select ".profile-project-list .project-list-row", text: /Marketing Website/, count: 0
  end

  test "should get edit" do
    get edit_profile_url
    assert_response :success
  end

  test "should update profile" do
    patch profile_url, params: { user: { name: "Alice Updated", email: "alice.updated@example.com", bio: "Updated" } }

    assert_redirected_to profile_url
    assert_equal "Alice Updated", @user.reload.name
  end

  test "should keep current password when password fields are blank" do
    original_password_digest = @user.password_digest

    patch profile_url, params: {
      user: {
        name: @user.name,
        email: @user.email,
        bio: @user.bio,
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to profile_url
    assert_equal original_password_digest, @user.reload.password_digest
  end

  test "should redirect show when not signed in" do
    delete session_url

    get profile_url

    assert_redirected_to new_session_url
  end
end
