# frozen_string_literal: true

require "cgi"
require "open3"
require "stringio"

puts "Seeding cabinet furniture demo data..."

rng = Random.new

document_fixture_path = Rails.root.join("test/fixtures/files/example.txt")

unless document_fixture_path.exist?
  raise "Seed fixture not found: #{document_fixture_path}"
end

def attach_fixture!(attachment_ref, source_path, filename, content_type)
  File.open(source_path, "rb") do |io|
    attachment_ref.attach(io:, filename:, content_type:)
  end
end

def build_placeholder_svg(title:, subtitle:, bg_color:, accent_color:)
  escaped_title = CGI.escapeHTML(title.to_s)
  escaped_subtitle = CGI.escapeHTML(subtitle.to_s)

  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800" viewBox="0 0 1200 800">
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#{bg_color}" />
          <stop offset="100%" stop-color="#0f172a" />
        </linearGradient>
      </defs>

      <rect width="1200" height="800" fill="url(#bg)" />
      <rect x="70" y="90" width="1060" height="620" rx="28" fill="#ffffff" opacity="0.06" />
      <rect x="70" y="300" width="1060" height="220" rx="24" fill="#020617" opacity="0.52" />
      <rect x="70" y="620" width="1060" height="64" rx="14" fill="#ffffff" opacity="0.12" />
      <circle cx="1045" cy="170" r="48" fill="#{accent_color}" opacity="0.95" />

      <text x="600" y="390" text-anchor="middle" fill="#f8fafc" font-family="Segoe UI, Tahoma, Arial, sans-serif" font-size="88" font-weight="800">
        #{escaped_title}
      </text>
      <text x="600" y="458" text-anchor="middle" fill="#e2e8f0" font-family="Segoe UI, Tahoma, Arial, sans-serif" font-size="50" font-weight="600">
        #{escaped_subtitle}
      </text>
      <text x="600" y="662" text-anchor="middle" fill="#cbd5e1" font-family="Segoe UI, Tahoma, Arial, sans-serif" font-size="28" font-weight="500">
        Корпусная мебель • демонстрационная заглушка
      </text>
    </svg>
  SVG
end

def render_png_from_svg!(svg_markup)
  png_data, status = Open3.capture2("convert", "svg:-", "png:-", stdin_data: svg_markup, binmode: true)
  raise "ImageMagick convert failed while building seed placeholder image" unless status.success?

  png_data
end

def attach_placeholder_image!(attachment_ref, filename:, title:, subtitle:, bg_color:, accent_color:)
  svg_markup = build_placeholder_svg(
    title: title,
    subtitle: subtitle,
    bg_color: bg_color,
    accent_color: accent_color
  )
  png_data = render_png_from_svg!(svg_markup)

  attachment_ref.attach(
    io: StringIO.new(png_data),
    filename: filename,
    content_type: "image/png"
  )
end

def reset_project_files!(project)
  project.project_attachment_descriptions.delete_all
  project.cover_image.purge if project.cover_image.attached?
  project.measurement_images.each(&:purge)
  project.example_files.each(&:purge)
  project.installation_photos.each(&:purge)
end

def create_attachment_descriptions!(project, rng)
  description_pool = [
    "Фасады МДФ в пленке, матовая текстура.",
    "Проверить зазор по левой стойке перед монтажом.",
    "Цвет согласован с заказчиком по образцу RAL.",
    "Направляющие скрытого монтажа с доводчиком.",
    "Кромка ПВХ 2 мм по внешнему контуру.",
    "Петли Blum, угол открывания 110 градусов."
  ]

  all_attachments = project.measurement_images.attachments + project.example_files.attachments + project.installation_photos.attachments
  all_attachments.each do |attachment|
    next if rng.rand < 0.2

    project.project_attachment_descriptions.create!(
      attachment: attachment,
      description: description_pool.sample(random: rng)
    )
  end
end

def create_project_changes!(project, rng)
  change_text_pool = [
    "Выполнен первичный замер и уточнены размеры ниши.",
    "Согласовали раскладку секций и количество выдвижных ящиков.",
    "Обновили проект по пожеланию заказчика: добавили антресоль.",
    "Утверждены материалы корпуса и фасадов, заказ передан в производство.",
    "Изготовлены и проверены основные модули перед отгрузкой.",
    "Проведен монтаж, выполнена регулировка фасадов и фурнитуры.",
    "Закрыли замечания после финального осмотра объекта."
  ]

  project.project_changes.destroy_all

  rng.rand(3..6).times do |index|
    project_change = project.project_changes.create!(
      description: change_text_pool.sample(random: rng)
    )
    project_change.update_column(
      :changed_at,
      rng.rand(2..75).days.ago.change(hour: rng.rand(9..19), min: [ 0, 10, 20, 30, 40, 50 ].sample(random: rng))
    )

    rng.rand(0..2).times do |image_index|
      attach_placeholder_image!(
        project_change.images,
        filename: "change-#{project.id}-#{index}-#{image_index}.png",
        title: "Изменение проекта ##{index + 1}",
        subtitle: "Фото этапа: #{project.display_name}",
        bg_color: "#334155",
        accent_color: "#38bdf8"
      )
    end
  end
end

users_data = [
  { name: "Илья Петров", email: "cabinet.master1@example.com", bio: "Проектировщик корпусной мебели.", password: "password123" },
  { name: "Ольга Смирнова", email: "cabinet.master2@example.com", bio: "Менеджер проектов по кухонным гарнитурам.", password: "password123" },
  { name: "Денис Волков", email: "cabinet.master3@example.com", bio: "Специалист по шкафам-купе и гардеробным.", password: "password123" }
]

products = [
  "Кухонный гарнитур П-образный",
  "Шкаф-купе в прихожую",
  "Гардеробная система под потолок",
  "ТВ-зона с подвесными модулями",
  "Рабочее место с пеналами",
  "Детская мебельная группа",
  "Буфет и витрина в гостиную",
  "Шкаф в санузел с нишей под коммуникации"
]

customers = [
  "ООО Север-Мебель",
  "ИП Кузнецов",
  "Семья Орловых",
  "ЖК Береговой, кв. 48",
  "Студия Интерьер Плюс",
  "Клиент Лебедева А."
]

addresses = [
  "Москва, ул. Профсоюзная, 47",
  "Москва, Ленинский пр-т, 89",
  "Химки, ул. Молодежная, 12",
  "Мытищи, ул. Колпакова, 6",
  "Красногорск, ул. Лесная, 19",
  "Одинцово, Можайское ш., 101"
]

places = [
  "Кухня",
  "Прихожая",
  "Спальня",
  "Гостиная",
  "Детская",
  "Офис"
]

statuses = [
  "Замер",
  "Проектирование",
  "Согласование",
  "В производстве",
  "Монтаж",
  "Сдан"
]

description_fragments = [
  "Корпус ЛДСП 16 мм, кромка ПВХ 2 мм.",
  "Фасады в матовой эмали, ручки-профиль скрытого типа.",
  "Предусмотрена подсветка рабочей зоны и витрин.",
  "Требуется аккуратная подгонка по стенам с отклонением геометрии.",
  "Фурнитура с доводчиками, усиленные направляющие полного выдвижения.",
  "Учитываем существующие розетки и выводы под технику."
]

users = users_data.map do |user_data|
  user = User.find_or_initialize_by(email: user_data[:email])
  user.name = user_data[:name]
  user.bio = user_data[:bio]
  user.password = user_data[:password]
  user.password_confirmation = user_data[:password]
  user.save!
  user
end

# Keep seed output predictable: clear previous demo projects for seed users.
users.each { |user| user.projects.destroy_all }

seeded_projects = []
project_target_count = 18

project_target_count.times do |index|
  user = users[index % users.size]
  product = products.sample(random: rng)
  customer_name = customers.sample(random: rng)
  address = addresses.sample(random: rng)

  project = user.projects.find_or_initialize_by(
    product: product,
    customer_name: customer_name,
    address: address
  )

  project.place = places.sample(random: rng)
  project.status = statuses.sample(random: rng)
  project.description = description_fragments.sample(2, random: rng).join(" ")
  project.save!

  seeded_projects << project
end

seeded_projects.each do |project|
  reset_project_files!(project)

  attach_placeholder_image!(
    project.cover_image,
    filename: "cover-#{project.id}.png",
    title: "Обложка проекта",
    subtitle: project.display_name,
    bg_color: "#1d4ed8",
    accent_color: "#f59e0b"
  )

  rng.rand(2..4).times do |index|
    attach_placeholder_image!(
      project.measurement_images,
      filename: "measurement-#{project.id}-#{index}.png",
      title: "Фото замера ##{index + 1}",
      subtitle: "Размеры и привязки помещения",
      bg_color: "#0f766e",
      accent_color: "#34d399"
    )
  end

  attach_placeholder_image!(
    project.example_files,
    filename: "example-image-#{project.id}.png",
    title: "Пример фасадов",
    subtitle: "Референс по материалам и дизайну",
    bg_color: "#7c3aed",
    accent_color: "#f472b6"
  )
  attach_fixture!(
    project.example_files,
    document_fixture_path,
    "example-doc-#{project.id}.txt",
    "text/plain"
  )

  rng.rand(1..3).times do |index|
    attach_placeholder_image!(
      project.installation_photos,
      filename: "install-#{project.id}-#{index}.png",
      title: "Фото монтажа ##{index + 1}",
      subtitle: "Установка и подгонка по месту",
      bg_color: "#b45309",
      accent_color: "#fde047"
    )
  end

  create_attachment_descriptions!(project, rng)
  create_project_changes!(project, rng)
end

puts "Seed complete: users=#{users.count}, projects=#{seeded_projects.count}"
