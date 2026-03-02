module ProjectsHelper
  def short_relative_time(time, now: Time.current)
    return "-" if time.blank?

    distance = (now - time).abs

    if distance < 3600
      minutes = [ (distance / 60).floor, 1 ].max
      "#{minutes} #{russian_plural(minutes, %w[минута минуты минут])}"
    else
      hours = [ (distance / 3600).floor, 1 ].max
      "#{hours} #{russian_plural(hours, %w[час часа часов])}"
    end
  end

  private

  def russian_plural(number, forms)
    return forms[2] if (11..14).cover?(number % 100)

    case number % 10
    when 1 then forms[0]
    when 2..4 then forms[1]
    else forms[2]
    end
  end
end
