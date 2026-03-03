require "test_helper"

class SharedProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @project.regenerate_share_link!
    @share_token = @project.share_token
  end

  test "shows shared project without top navigation" do
    get shared_project_url(@share_token)

    assert_response :success
    assert_select "header", count: 0
    assert_select "nav", count: 0
    assert_select "h1", text: @project.display_name, count: 1
    assert_select ".project-author-row a.button-link", text: "Поделиться", count: 0
    assert_select ".project-author-row a.button-link", text: "Редакция", count: 0
    assert_select ".project-author-row a.button-link", text: "Удалить", count: 0
    assert_select "h2", text: "Add change entry", count: 0
  end

  test "returns not found for invalid share token" do
    get shared_project_url("invalid-token")

    assert_response :not_found
  end

  test "returns not found for tampered share token" do
    get shared_project_url("#{@share_token}tampered")

    assert_response :not_found
  end

  test "returns not found for expired share token" do
    @project.update_column(:share_token_expires_at, 1.minute.ago)

    get shared_project_url(@share_token)

    assert_response :not_found
  end

  test "shared page hides owner controls for signed-in owner" do
    post session_url, params: { session: { email: @project.user.email, password: "password123" } }

    get shared_project_url(@share_token)

    assert_response :success
    assert_select ".project-author-row a.button-link", count: 0
    assert_select "h2", text: "Add change entry", count: 0
  end
end
