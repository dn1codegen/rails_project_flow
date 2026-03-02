require "test_helper"

class ProjectChangeTest < ActiveSupport::TestCase
  test "sets changed_at automatically on create" do
    project_change = projects(:one).project_changes.new(
      description: "Added reporting and export capabilities."
    )

    assert project_change.valid?
    assert_not_nil project_change.changed_at
  end

  test "overrides provided changed_at with current time on create" do
    custom_date = Time.zone.parse("2020-01-01 12:00:00")

    project_change = projects(:one).project_changes.new(
      description: "This description is long enough.",
      changed_at: custom_date
    )

    project_change.valid?

    assert_operator project_change.changed_at, :>, 1.minute.ago
  end

  test "is invalid with short description" do
    project_change = projects(:one).project_changes.new(
      description: "Nope"
    )

    assert_not project_change.valid?
    assert_includes project_change.errors[:description], "is too short (minimum is 5 characters)"
  end
end
