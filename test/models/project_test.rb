require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "is invalid without product on create" do
    project = Project.new(user: users(:one), description: "A long enough description.")

    assert_not project.valid?
    assert_includes project.errors[:product], "can't be blank"
  end

  test "is invalid with short product" do
    project = Project.new(user: users(:one), product: "No", description: "A long enough description.")

    assert_not project.valid?
    assert_includes project.errors[:product], "is too short (minimum is 3 characters)"
  end

  test "sets title from product before validation" do
    project = Project.new(user: users(:one), product: "Entrance scanner", description: "A long enough description.")

    assert project.valid?
    assert_equal "Entrance scanner", project.title
  end

  test "is invalid with short description" do
    project = Project.new(user: users(:one), product: "Valid product", description: "Too short")

    assert_not project.valid?
    assert_includes project.errors[:description], "is too short (minimum is 10 characters)"
  end

  test "destroys associated project changes" do
    project = projects(:one)

    assert_difference("ProjectChange.count", -project.project_changes.count) do
      project.destroy
    end
  end
end
