require "test_helper"

class ProjectsHelperTest < ActionView::TestCase
  test "returns zero days-hours format when time is blank" do
    assert_equal "00/00", short_relative_time(nil)
  end

  test "returns zero days and hours when distance is below one hour" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 25.minutes

    assert_equal "00/00", short_relative_time(time, now: now)
  end

  test "returns days-hours format for exact 24 hours" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 24.hours

    assert_equal "01/00", short_relative_time(time, now: now)
  end

  test "returns days with remaining hours using slash separator" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 49.hours

    assert_equal "02/01", short_relative_time(time, now: now)
  end

  test "shows zero-padded hours for exact number of days" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 48.hours

    assert_equal "02/00", short_relative_time(time, now: now)
  end
end
