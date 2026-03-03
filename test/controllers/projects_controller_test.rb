require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @other_user = users(:two)
    @project = projects(:one)
  end

  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "index navigation includes archive tab" do
    get projects_url

    assert_response :success
    assert_select "nav a", text: "Архив", count: 1
  end

  test "should get archive" do
    get archive_projects_url

    assert_response :success
    assert_select "h1", text: "Архив проектов", count: 1
    assert_select "form.archive-search-form[action='#{archive_projects_path}'][method='get']", count: 1
    assert_select "form.archive-search-form .archive-search-icon-button[type='submit'][aria-label='Искать']", count: 1
    assert_select "form.archive-search-form input[type='submit'][value='Найти']", count: 0
    assert_select ".archive-year-filters", count: 1
    assert_select "a.archive-year-button.is-active", text: "Все", count: 1
    assert_select ".archive-month-filters", count: 0
  end

  test "archive filters projects by query" do
    matching_project = Project.create!(
      user: @user,
      product: "Шкаф-купе Лофт",
      customer_name: "Семья Орловых",
      address: "Казань, ул. Мира, 7",
      description: "Проект шкафа-купе для прихожей с матовыми фасадами."
    )
    Project.create!(
      user: @user,
      product: "Офисные шкафы Модуль",
      customer_name: "ИП Смирнов",
      address: "Самара, ул. Победы, 12",
      description: "Корпусная мебель для зоны документов в офисе."
    )

    get archive_projects_url, params: { q: "Орловых" }

    assert_response :success
    assert_select ".project-list-row", text: /#{Regexp.escape(matching_project.display_name)}/, count: 1
    assert_select ".project-list-row", text: /Офисные шкафы Модуль/, count: 0
  end

  test "archive filters projects by selected year" do
    project_2021 = Project.create!(
      user: @user,
      product: "Гардероб 2021",
      customer_name: "Клиент 2021",
      address: "Тверь, ул. Проектная, 11",
      description: "Описание проекта корпусной мебели для архива 2021."
    )
    project_2024 = Project.create!(
      user: @user,
      product: "Гардероб 2024",
      customer_name: "Клиент 2024",
      address: "Тверь, ул. Проектная, 24",
      description: "Описание проекта корпусной мебели для архива 2024."
    )

    project_2021.update_columns(
      created_at: Time.zone.parse("2021-05-10 12:00:00"),
      updated_at: Time.zone.parse("2021-05-10 12:00:00")
    )
    project_2024.update_columns(
      created_at: Time.zone.parse("2024-08-15 12:00:00"),
      updated_at: Time.zone.parse("2024-08-15 12:00:00")
    )

    get archive_projects_url, params: { year: "2021" }

    assert_response :success
    assert_select "a.archive-year-button.is-active", text: "21", count: 1
    assert_select "form.archive-search-form input[name='year'][value='2021']", count: 1
    assert_select ".archive-month-filters", count: 1
    assert_select ".project-list-row", text: /#{Regexp.escape(project_2021.display_name)}/, count: 1
    assert_select ".project-list-row", text: /#{Regexp.escape(project_2024.display_name)}/, count: 0
  end

  test "archive filters projects by selected month and hides author column" do
    travel_to Time.zone.parse("2021-05-22 11:00:00") do
      may_project = Project.create!(
        user: @user,
        product: "Шкаф май",
        customer_name: "Клиент май",
        address: "Пермь, ул. Майская, 1",
        description: "Проект для теста фильтра по месяцу."
      )
      august_project = Project.create!(
        user: @user,
        product: "Шкаф август",
        customer_name: "Клиент август",
        address: "Пермь, ул. Августовская, 8",
        description: "Проект для теста фильтра по месяцу."
      )

      may_project.update_columns(
        created_at: Time.zone.parse("2021-05-20 11:00:00"),
        updated_at: Time.zone.parse("2021-05-20 11:00:00")
      )
      august_project.update_columns(
        created_at: Time.zone.parse("2021-08-10 11:00:00"),
        updated_at: Time.zone.parse("2021-08-10 11:00:00")
      )
      may_change = may_project.project_changes.create!(description: "Последнее обновление проекта.")
      may_change.update_column(:changed_at, Time.zone.parse("2021-05-20 11:00:00"))

      get archive_projects_url, params: { year: "2021", month: "5" }

      assert_response :success
      assert_select ".archive-month-filters a.archive-year-button.is-active", text: "Май", count: 1
      assert_select "form.archive-search-form input[name='year'][value='2021']", count: 1
      assert_select "form.archive-search-form input[name='month'][value='5']", count: 1
      assert_select ".project-list-header .project-list-changes", count: 0
      assert_select ".project-list-header .project-list-time", text: "ВРЕМЯ", count: 1
      assert_select ".project-list-row", text: /#{Regexp.escape(may_project.display_name)}/, count: 1
      assert_select ".project-list-row", text: /#{Regexp.escape(august_project.display_name)}/, count: 0
      assert_select ".project-list-row .project-list-time", text: "2 д", count: 1
    end
  end

  test "index shows header and relative time format for project row" do
    travel_to Time.zone.parse("2026-03-03 12:00:00") do
      get projects_url

      assert_response :success
      assert_select ".project-list-block-title", text: /\AПроекты до года\s+\d+\z/, count: 1
      assert_select ".project-list-block-count", text: /\A\d+\z/
      assert_select ".project-list-header .project-list-title-label", text: "ПРОЕКТ", count: 1
      assert_select ".project-list-header .project-limit-button", count: 4
      assert_select ".project-list-header .project-limit-button.is-active", text: "10", count: 1
      assert_select ".project-list-header .project-list-changes", text: "ИЗМ", count: 1
      assert_select ".project-list-header .project-list-time", text: "ВРЕМЯ", count: 1
      assert_select ".project-list-changes", text: /\A\d+\z/
      assert_select ".project-list-time", text: /\A\d+\s(ч|д)\z/
    end
  end

  test "index limits project rows by selected recent edits count" do
    travel_to Time.zone.parse("2026-03-03 12:00:00") do
      12.times do |index|
        project = Project.create!(
          user: @user,
          product: "Limited Project #{index}",
          description: "Description long enough for limited project #{index}."
        )
        change = project.project_changes.create!(description: "Recent update #{index}.")
        change.update_column(:changed_at, index.hours.ago)
      end

      get projects_url, params: { limit: 10 }

      assert_response :success
      assert_select ".project-list-header .project-limit-button.is-active", text: "10", count: 1
      assert_select "a.project-list-row", count: 10
    end
  end

  test "index keeps one block for projects not older than year and sorts by last edit date" do
    travel_to Time.zone.parse("2026-03-03 12:00:00") do
      month_project = Project.create!(
        user: @user,
        product: "Month Bucket Project",
        description: "Description long enough for month bucket project."
      )
      month_change = month_project.project_changes.create!(
        description: "Recent update for month bucket.",
        changed_at: 15.days.ago
      )
      month_change.update_column(:changed_at, 15.days.ago)

      quarter_project = Project.create!(
        user: @user,
        product: "Quarter Bucket Project",
        description: "Description long enough for quarter bucket project."
      )
      quarter_change = quarter_project.project_changes.create!(
        description: "Middle update for quarter bucket.",
        changed_at: 2.months.ago
      )
      quarter_change.update_column(:changed_at, 2.months.ago)

      year_project = Project.create!(
        user: @user,
        product: "Year Bucket Project",
        description: "Description long enough for year bucket project."
      )
      year_change = year_project.project_changes.create!(
        description: "Old update for year bucket.",
        changed_at: 8.months.ago
      )
      year_change.update_column(:changed_at, 8.months.ago)

      old_project = Project.create!(
        user: @user,
        product: "Too Old Project",
        description: "Description long enough for old bucket project."
      )
      old_change = old_project.project_changes.create!(
        description: "Too old update that should not be shown on index.",
        changed_at: 14.months.ago
      )
      old_project.update_column(:updated_at, 14.months.ago)
      old_change.update_column(:changed_at, 14.months.ago)

      get projects_url

      assert_response :success
      assert_select ".project-list-block-title", text: /\AПроекты до года\s+\d+\z/, count: 1
      assert_select "section.project-list", count: 1
      assert_select "a.project-list-row", text: /Month Bucket Project/, count: 1
      assert_select "a.project-list-row", text: /Quarter Bucket Project/, count: 1
      assert_select "a.project-list-row", text: /Year Bucket Project/, count: 1
      assert_select "a.project-list-row", text: /Too Old Project/, count: 0

      row_numbers = css_select("section.project-list .project-list-row-number").map { |node| node.text.strip }
      assert_includes row_numbers, "1."
      assert_includes row_numbers, "2."
      assert_includes row_numbers, "3."
    end
  end

  test "index uses project change timestamp and ignores newer project updated_at" do
    travel_to Time.zone.parse("2026-03-03 12:00:00") do
      project = Project.create!(
        user: @user,
        product: "Mismatch Time Project",
        description: "Description long enough for last edit timestamp check."
      )
      project.update_column(:updated_at, Time.zone.parse("2026-03-02 10:00:00"))
      change = project.project_changes.create!(description: "History entry for timestamp comparison.")
      change.update_column(:changed_at, Time.zone.parse("2026-02-20 12:00:00"))

      get projects_url, params: { limit: 100 }

      assert_response :success
      project_row = css_select("a.project-list-row").find { |row| row.text.include?("Mismatch Time Project") }
      assert project_row
      assert_equal "11 д", project_row.at_css(".project-list-time")&.text&.strip
    end
  end

  test "index shows customer name and address for project row" do
    @project.update!(customer_name: "ООО Ромашка", address: "ул. Ленина, 5")

    get projects_url

    assert_response :success
    assert_select ".project-list-title small", text: "ООО Ромашка • ул. Ленина, 5", count: 1
  end

  test "index renders cover thumbnail on project row when cover is attached" do
    @project.cover_image.attach(file_fixture_upload("sample.svg", "image/svg+xml"))

    get projects_url

    assert_response :success
    assert_select "a.project-list-row .project-list-cover-preview", count: 1
    assert_select "a.project-list-row .project-list-cover-preview img.project-list-cover-image", count: 1
  end

  test "should get show" do
    get project_url(@project)
    assert_response :success
  end

  test "show displays created timestamp and uses latest change timestamp for last modification" do
    created_at = Time.zone.parse("2026-01-10 09:15:00")
    updated_at = Time.zone.parse("2026-01-12 14:45:00")
    @project.update_columns(created_at: created_at, updated_at: updated_at)
    @project.project_changes.destroy_all

    get project_url(@project)

    assert_response :success
    assert_select ".project-author-dates", text: /Создан:/, count: 1
    assert_select ".project-author-dates", text: /Изменен:/, count: 1
    assert_includes @response.body, I18n.l(created_at, format: :long)
    assert_not_includes @response.body, I18n.l(updated_at, format: :long)
  end

  test "show renders project cover image at top" do
    @project.cover_image.attach(file_fixture_upload("sample.svg", "image/svg+xml"))

    get project_url(@project)

    assert_response :success
    assert_select ".project-cover button.project-cover-button[data-lightbox-target='image']", count: 1
    assert_select ".project-cover img.project-cover-image", count: 1
  end

  test "show renders history images without filename links" do
    project_change = @project.project_changes.create!(description: "Added build screenshots for review.")
    image = file_fixture_upload("sample.svg", "image/svg+xml")
    project_change.images.attach(image)

    get project_url(@project)

    assert_response :success
    assert_select "div[data-controller='lightbox']", 1
    assert_select "button.history-change-image[data-lightbox-target='image']", 1
    assert_select "button.history-change-image", text: image.original_filename, count: 0
  end

  test "show renders project attachment images as lightbox items" do
    measurement_image = file_fixture_upload("sample.svg", "image/svg+xml")
    example_image = file_fixture_upload("sample.svg", "image/svg+xml")
    example_document = file_fixture_upload("example.txt", "text/plain")
    installation_photo = file_fixture_upload("sample.svg", "image/svg+xml")

    @project.measurement_images.attach(measurement_image)
    @project.example_files.attach(example_image)
    @project.example_files.attach(example_document)
    @project.installation_photos.attach(installation_photo)
    @project.project_attachment_descriptions.create!(
      attachment: @project.measurement_images.attachments.first,
      description: "Description for first measurement image."
    )

    get project_url(@project)

    assert_response :success
    assert_select "article.card h2", text: "Attached files", count: 1
    assert_select "button.history-change-image[data-lightbox-target='image']", count: 3
    assert_select "button[data-lightbox-description='Description for first measurement image.']", count: 1
    assert_select ".lightbox-description[data-lightbox-target='description']", count: 1
    assert_select "a", text: "example.txt", count: 1
    assert_select ".attachment-description", text: "Description for first measurement image.", count: 1
  end

  test "show displays per-image description action hints for owner" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    with_description = file_fixture_upload("sample.svg", "image/svg+xml")
    without_description = file_fixture_upload("sample.svg", "image/svg+xml")

    @project.measurement_images.attach(with_description)
    @project.measurement_images.attach(without_description)

    described_attachment = @project.measurement_images.attachments.first
    @project.project_attachment_descriptions.create!(
      attachment: described_attachment,
      description: "Already has description."
    )

    get project_url(@project)

    assert_response :success
    assert_select "a.attachment-description-hint", text: "Изменить описание", count: 1
    assert_select "a.attachment-description-hint", text: "Добавить описание", count: 1
  end

  test "show aligns author and owner actions in a single row for owner" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    get project_url(@project)

    assert_response :success
    assert_select ".project-author-row", count: 1
    assert_select ".project-author-row .project-author small", text: @project.user.name, count: 1
    assert_select ".project-author-row a.button-link", text: "Edit project", count: 1
    assert_select ".project-author-row a.button-link.button-link-danger", text: "Delete project", count: 1
    assert_select ".project-share-block", count: 1
    assert_select ".project-share-block .project-share-title", text: "Ссылка на проект", count: 1
    assert_select ".project-share-block a.button-link", text: "Создать ссылку", count: 1
    assert_select ".project-share-status", text: /Ссылка для просмотра еще не создана/, count: 1
  end

  test "show displays active share link and remaining lifetime for owner" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }
    @project.regenerate_share_link!(now: Time.zone.parse("2026-03-03 10:00:00"))

    travel_to Time.zone.parse("2026-03-03 12:00:00") do
      get project_url(@project)
    end

    assert_response :success
    assert_select ".project-share-block a.button-link", text: "Поделиться", count: 1
    assert_select ".project-share-status", text: /Ссылка активна еще/, count: 1
    assert_select ".project-share-status", text: /3 д 22 ч/, count: 1
  end

  test "owner can regenerate expired share link" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }
    @project.update_columns(share_token: "expired-token", share_token_expires_at: 2.days.ago)

    assert_changes -> { @project.reload.share_token } do
      post refresh_share_link_project_url(@project)
    end

    assert_redirected_to project_url(@project)
    assert @project.reload.active_share_link?
  end

  test "non-owner cannot regenerate share link" do
    post session_url, params: { session: { email: @other_user.email, password: "password123" } }
    @project.update_columns(share_token: "owner-token", share_token_expires_at: 2.days.from_now)
    original_token = @project.share_token

    post refresh_share_link_project_url(@project)

    assert_redirected_to project_url(@project)
    assert_equal original_token, @project.reload.share_token
  end

  test "should redirect new when not signed in" do
    get new_project_url

    assert_redirected_to new_session_url
  end

  test "new form uses product field instead of title field" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    get new_project_url

    assert_response :success
    assert_select "input[name='project[title]']", count: 0
    assert_select "input[name='project[product]'][required]"
    assert_select "input[name='project[cover_image]'][type='file']", count: 1
  end

  test "should create project when signed in" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    cover_image = file_fixture_upload("sample.svg", "image/svg+xml")
    measurement = file_fixture_upload("sample.svg", "image/svg+xml")
    example_doc = file_fixture_upload("example.txt", "text/plain")
    installation_photo = file_fixture_upload("sample.svg", "image/svg+xml")

    assert_difference("Project.count", 1) do
      post projects_url, params: {
        project: {
          description: "Build a command line app for editors.",
          customer_name: "ООО Альфа",
          address: "ул. Пример, 1",
          place: "Склад №2",
          product: "Терминал доступа",
          status: "В работе",
          cover_image: cover_image,
          measurement_images: [ measurement ],
          example_files: [ example_doc ],
          installation_photos: [ installation_photo ]
        }
      }
    end

    assert_response :redirect
    created_project = Project.order(:created_at).last
    assert_equal "Терминал доступа", created_project.title
    assert_equal "ООО Альфа", created_project.customer_name
    assert_equal "ул. Пример, 1", created_project.address
    assert_equal "Склад №2", created_project.place
    assert_equal "Терминал доступа", created_project.product
    assert_equal "В работе", created_project.status
    assert created_project.cover_image.attached?
    assert created_project.measurement_images.attached?
    assert created_project.example_files.attached?
    assert created_project.installation_photos.attached?
  end

  test "should redirect create when not signed in" do
    assert_no_difference("Project.count") do
      post projects_url, params: {
        project: {
          product: "Unauthorized project",
          description: "A project creation attempt without authentication."
        }
      }
    end

    assert_redirected_to new_session_url
  end

  test "should update own project" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    patch project_url(@project), params: {
      project: {
        description: @project.description,
        customer_name: "Заказчик A",
        address: "Новый адрес, 10",
        place: "Офис",
        product: "Камера",
        status: "Завершен"
      }
    }

    assert_redirected_to project_url(@project)
    assert_equal "Камера", @project.reload.title
    assert_equal "Заказчик A", @project.customer_name
    assert_equal "Новый адрес, 10", @project.address
    assert_equal "Офис", @project.place
    assert_equal "Камера", @project.product
    assert_equal "Завершен", @project.status
  end

  test "should keep existing attachments when update contains blank file inputs" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    @project.measurement_images.attach(file_fixture_upload("sample.svg", "image/svg+xml"))
    @project.example_files.attach(file_fixture_upload("example.txt", "text/plain"))
    @project.installation_photos.attach(file_fixture_upload("sample.svg", "image/svg+xml"))

    patch project_url(@project), params: {
      project: {
        description: @project.description,
        measurement_images: [ "" ],
        example_files: [ "" ],
        installation_photos: [ "" ]
      }
    }

    assert_redirected_to project_url(@project)
    @project.reload
    assert @project.measurement_images.attached?
    assert @project.example_files.attached?
    assert @project.installation_photos.attached?
  end

  test "should append new attachments on update instead of replacing existing ones" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    @project.measurement_images.attach(file_fixture_upload("sample.svg", "image/svg+xml"))

    new_measurement_image = file_fixture_upload("sample.svg", "image/svg+xml")

    patch project_url(@project), params: {
      project: {
        description: @project.description,
        measurement_images: [ new_measurement_image ]
      }
    }

    assert_redirected_to project_url(@project)
    assert_equal 2, @project.reload.measurement_images.count
  end

  test "should remove selected attachments and related descriptions on update" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    @project.measurement_images.attach(file_fixture_upload("sample.svg", "image/svg+xml"))
    attachment = @project.measurement_images.attachments.first
    @project.project_attachment_descriptions.create!(
      attachment: attachment,
      description: "Description that should be deleted with file."
    )

    patch project_url(@project), params: {
      project: {
        description: @project.description,
        remove_attachment_ids: [ attachment.id ]
      }
    }

    assert_redirected_to project_url(@project)
    @project.reload
    assert_equal 0, @project.measurement_images.attachments.count
    assert_nil @project.project_attachment_descriptions.find_by(attachment_id: attachment.id)
  end

  test "should remove project cover image on update" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    @project.cover_image.attach(file_fixture_upload("sample.svg", "image/svg+xml"))

    patch project_url(@project), params: {
      project: {
        description: @project.description,
        remove_cover_image: "1"
      }
    }

    assert_redirected_to project_url(@project)
    assert_not @project.reload.cover_image.attached?
  end

  test "should save per-file descriptions on update" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    @project.measurement_images.attach(file_fixture_upload("sample.svg", "image/svg+xml"))
    attachment = @project.measurement_images.attachments.first

    patch project_url(@project), params: {
      project: {
        description: @project.description,
        attachment_descriptions: {
          attachment.id => "File description for measurement image."
        }
      }
    }

    assert_redirected_to project_url(@project)

    @project.reload
    updated_attachment = @project.measurement_images.attachments.find(attachment.id)
    assert_equal "File description for measurement image.", @project.attachment_description_for(updated_attachment)
  end

  test "should redirect edit for non-owner" do
    post session_url, params: { session: { email: @other_user.email, password: "password123" } }

    get edit_project_url(@project)

    assert_redirected_to project_url(@project)
  end

  test "should not update project for non-owner" do
    post session_url, params: { session: { email: @other_user.email, password: "password123" } }

    patch project_url(@project), params: {
      project: {
        title: "Hacked title",
        description: @project.description
      }
    }

    assert_redirected_to project_url(@project)
    assert_not_equal "Hacked title", @project.reload.title
  end

  test "should destroy own project" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

    assert_difference("Project.count", -1) do
      delete project_url(@project)
    end

    assert_redirected_to projects_url
  end

  test "should not destroy project for non-owner" do
    post session_url, params: { session: { email: @other_user.email, password: "password123" } }

    assert_no_difference("Project.count") do
      delete project_url(@project)
    end

    assert_redirected_to project_url(@project)
  end
end
