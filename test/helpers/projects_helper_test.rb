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

  test "relative hours or days uses hours for up to 24 hours" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 10.hours

    assert_equal "10 ч", relative_hours_or_days(time, now: now)
  end

  test "relative hours or days uses days for more than 24 hours up to 30 days" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 3.days

    assert_equal "3 д", relative_hours_or_days(time, now: now)
  end

  test "relative hours or days keeps days for exactly 30 days" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 30.days

    assert_equal "30 д", relative_hours_or_days(time, now: now)
  end

  test "relative hours or days uses months with one decimal after 30 days" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 45.days

    assert_equal "1,5 м", relative_hours_or_days(time, now: now)
  end

  test "relative hours or days keeps months format up to 12 months" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 360.days

    assert_equal "12,0 м", relative_hours_or_days(time, now: now)
  end

  test "relative hours or days uses years with one decimal after 12 months" do
    now = Time.zone.parse("2026-03-03 12:00:00")
    time = now - 400.days

    assert_equal "1,1 г", relative_hours_or_days(time, now: now)
  end
end
