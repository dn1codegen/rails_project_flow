require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @project = projects(:one)
  end

  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "index shows compact relative last change for project row" do
    get projects_url

    assert_response :success
    assert_select ".project-list-changes", text: /\A\d+\z/
    assert_select ".project-list-time", text: /\d+\s+(?:минута|минуты|минут|час|часа|часов)/
  end

  test "index shows customer name and address for project row" do
    @project.update!(customer_name: "ООО Ромашка", address: "ул. Ленина, 5")

    get projects_url

    assert_response :success
    assert_select ".project-list-title small", text: "ООО Ромашка • ул. Ленина, 5", count: 1
  end

  test "should get show" do
    get project_url(@project)
    assert_response :success
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
  end

  test "should create project when signed in" do
    post session_url, params: { session: { email: @user.email, password: "password123" } }

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
end
