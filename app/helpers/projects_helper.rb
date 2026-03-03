module ProjectsHelper
  def short_relative_time(time, now: Time.current)
    return "-" if time.blank?

    distance = (now - time).abs

    if distance < 3600
      minutes = [ (distance / 60).floor, 1 ].max
      "#{minutes} М"
    elsif distance > 24.hours
      total_hours = (distance / 3600).floor
      days = total_hours / 24
      remaining_hours = total_hours % 24

      "#{days} Д #{remaining_hours} Ч"
    else
      hours = [ (distance / 3600).floor, 1 ].max
      "#{hours} Ч"
    end
  end
end
