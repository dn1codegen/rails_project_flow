module ProjectsHelper
  ARCHIVE_MONTH_NAMES = [
    nil,
    "Январь",
    "Февраль",
    "Март",
    "Апрель",
    "Май",
    "Июнь",
    "Июль",
    "Август",
    "Сентябрь",
    "Октябрь",
    "Ноябрь",
    "Декабрь"
  ].freeze

  def short_relative_time(time, now: Time.current)
    return "00/00" if time.blank?

    total_hours = ((now - time).abs / 3600).floor
    days = total_hours / 24
    hours = total_hours % 24

    format("%<days>02d/%<hours>02d", days: days, hours: hours)
  end

  def relative_hours_or_days(time, now: Time.current)
    return "0 ч" if time.blank?

    total_hours = ((now - time).abs / 3600).floor
    return "#{total_hours} ч" if total_hours <= 24

    total_days = total_hours / 24.0
    return "#{total_days.floor} д" if total_days <= 30

    months = total_days / 30.0
    return "#{format('%.1f', months).tr('.', ',')} м" if months <= 12

    years = months / 12.0
    "#{format('%.1f', years).tr('.', ',')} г"
  end

  def project_last_activity_at(project)
    project.project_changes.first&.changed_at || project.created_at
  end

  def share_link_time_left(expires_at, now: Time.current)
    return "0 ч" if expires_at.blank? || expires_at <= now

    total_hours = ((expires_at - now) / 3600.0).ceil
    return "#{total_hours} ч" if total_hours < 24

    days = total_hours / 24
    hours = total_hours % 24
    return "#{days} д" if hours.zero?

    "#{days} д #{hours} ч"
  end

  def archive_month_name(month_number)
    month = month_number.to_i
    ARCHIVE_MONTH_NAMES.fetch(month, format("%02d", month))
  end
end
