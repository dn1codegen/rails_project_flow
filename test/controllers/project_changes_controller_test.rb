require "test_helper"

class ProjectChangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @project = projects(:one)
  end

  test "should create project change" do
    sign_in_as(@user)
    image = file_fixture_upload("sample.svg", "image/svg+xml")

    assert_difference("ProjectChange.count", 1) do
      post project_project_changes_url(@project), params: {
        project_change: {
          description: "Released first stable version.",
          images: [ image ]
        }
      }
    end

    assert_redirected_to project_url(@project)
    created_change = ProjectChange.order(:created_at).last
    assert_operator created_change.changed_at, :>, 1.minute.ago
    assert created_change.images.attached?
  end

  test "should redirect create when not signed in" do
    assert_no_difference("ProjectChange.count") do
      post project_project_changes_url(@project), params: {
        project_change: {
          description: "Released first stable version."
        }
      }
    end

    assert_redirected_to new_session_url
  end

  test "should not create project change for non-owner" do
    sign_in_as(@other_user)

    assert_no_difference("ProjectChange.count") do
      post project_project_changes_url(@project), params: {
        project_change: {
          description: "Trying to add history to another user's project."
        }
      }
    end

    assert_redirected_to project_url(@project)
  end

  test "should render show with errors when invalid" do
    sign_in_as(@user)

    assert_no_difference("ProjectChange.count") do
      post project_project_changes_url(@project), params: {
        project_change: {
          description: "Bad"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  private

  def sign_in_as(user)
    post session_url, params: { session: { email: user.email, password: "password123" } }
  end
end
