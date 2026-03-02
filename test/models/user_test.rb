require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email before validation" do
    user = User.new(
      name: "Charlie",
      email: "  CHarlie@Example.COM ",
      password: "password123",
      password_confirmation: "password123"
    )

    user.valid?

    assert_equal "charlie@example.com", user.email
  end

  test "is invalid with duplicate email regardless of case" do
    user = User.new(
      name: "Another Alice",
      email: "ALICE@EXAMPLE.COM",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "is invalid without name" do
    user = User.new(
      name: "",
      email: "valid@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "is invalid with malformed email" do
    user = User.new(
      name: "Charlie",
      email: "not-an-email",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end
end
