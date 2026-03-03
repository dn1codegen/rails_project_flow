module ProjectsHelper
  def short_relative_time(time, now: Time.current)
    return "00/00" if time.blank?

    total_hours = ((now - time).abs / 3600).floor
    days = total_hours / 24
    hours = total_hours % 24

    format("%<days>02d/%<hours>02d", days: days, hours: hours)
  end
end
