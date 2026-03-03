require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { session: { email: @user.email, password: "password123" } }
  end

  test "should get show" do
    get profile_url
    assert_response :success
    assert_select ".profile-active-shares", count: 1
    assert_select ".profile-active-shares .project-list-row", count: 0
    assert_select ".profile-active-shares p", text: "Нет активных ссылок.", count: 1
    assert_select ".archive-year-filters", count: 1
    assert_select "form.archive-search-form[action='#{profile_path}'][method='get']", count: 1
    assert_select ".profile-project-list", count: 1
    assert_select ".profile-project-list .project-list-block-title", text: /Последние измененные проекты/, count: 1
    assert_select ".profile-project-list .project-list-row", count: 1
  end

  test "profile shows only 10 latest changed projects before search" do
    base_time = Time.zone.parse("2026-03-03 12:00:00")

    12.times do |index|
      project = Project.create!(
        user: @user,
        product: format("Измененный проект %02d", index + 1),
        customer_name: format("Клиент %02d", index + 1),
        address: "Казань, ул. Тестовая, #{index + 1}",
        description: "Проект для проверки последних изменений #{index + 1}."
      )
      change = project.project_changes.create!(description: "Обновление #{index + 1}.")
      change.update_column(:changed_at, base_time + index.minutes)
    end

    project_without_changes = Project.create!(
      user: @user,
      product: "Без изменений",
      customer_name: "Клиент без изменений",
      address: "Казань, ул. Без изменений, 1",
      description: "Этот проект не должен попасть в список последних изменений."
    )
    project_without_changes.update_column(:created_at, base_time + 20.minutes)

    get profile_url

    assert_response :success
    assert_select ".profile-project-list .project-list-row", count: 10
    assert_select ".profile-project-list .project-list-row", text: /Измененный проект 12/, count: 1
    assert_select ".profile-project-list .project-list-row", text: /Измененный проект 03/, count: 1
    assert_select ".profile-project-list .project-list-row", text: /Измененный проект 02/, count: 0
    assert_select ".profile-project-list .project-list-row", text: /Без изменений/, count: 0
  end

  test "profile shows only non-expired share links" do
    active_project = Project.create!(
      user: @user,
      product: "Активная ссылка",
      customer_name: "Клиент активный",
      address: "Казань, ул. Активная, 1",
      description: "Проект с активной ссылкой."
    )
    expired_project = Project.create!(
      user: @user,
      product: "Просроченная ссылка",
      customer_name: "Клиент просроченный",
      address: "Казань, ул. Просроченная, 2",
      description: "Проект с просроченной ссылкой."
    )

    active_project.regenerate_share_link!(now: Time.zone.parse("2026-03-03 10:00:00"))
    expired_project.regenerate_share_link!(now: Time.zone.parse("2026-03-01 10:00:00"))
    expired_project.update_column(:share_token_expires_at, 1.hour.ago)

    get profile_url

    assert_response :success
    assert_select ".profile-active-shares .project-list-row", text: /Активная ссылка/, count: 1
    assert_select ".profile-active-shares .project-list-row", text: /Просроченная ссылка/, count: 0
    assert_select ".profile-active-shares a[href='#{shared_project_path(active_project.share_token)}']", count: 1
  end

  test "profile filters user projects by query year and month like archive" do
    may_project = Project.create!(
      user: @user,
      product: "Шкаф Лофт",
      customer_name: "Семья Орловых",
      address: "Казань, ул. Мира, 7",
      description: "Проект для профиля пользователя."
    )
    august_project = Project.create!(
      user: @user,
      product: "Шкаф Лофт",
      customer_name: "Семья Петровых",
      address: "Казань, ул. Мира, 7",
      description: "Проект для профиля пользователя."
    )
    other_user_project = Project.create!(
      user: users(:two),
      product: "Шкаф Лофт",
      customer_name: "Семья Орловых Чужие",
      address: "Казань, ул. Мира, 7",
      description: "Чужой проект не должен попадать в профиль."
    )

    may_project.update_columns(
      created_at: Time.zone.parse("2021-05-10 12:00:00"),
      updated_at: Time.zone.parse("2021-05-10 12:00:00")
    )
    august_project.update_columns(
      created_at: Time.zone.parse("2021-08-15 12:00:00"),
      updated_at: Time.zone.parse("2021-08-15 12:00:00")
    )
    other_user_project.update_columns(
      created_at: Time.zone.parse("2021-05-20 12:00:00"),
      updated_at: Time.zone.parse("2021-05-20 12:00:00")
    )

    get profile_url, params: { q: "лОФТ орЛОВЫХ", year: "2021", month: "5" }

    assert_response :success
    assert_select ".archive-month-filters a.archive-year-button.is-active", text: "Май", count: 1
    assert_select "form.archive-search-form input[name='year'][value='2021']", count: 1
    assert_select "form.archive-search-form input[name='month'][value='5']", count: 1
    assert_select ".profile-project-list .project-list-row", text: /Семья Орловых/, count: 1
    assert_select ".profile-project-list .project-list-row", text: /Семья Петровых/, count: 0
    assert_select ".profile-project-list .project-list-row", text: /Орловых Чужие/, count: 0
  end

  test "should get edit" do
    get edit_profile_url
    assert_response :success
  end

  test "should update profile" do
    patch profile_url, params: { user: { name: "Alice Updated", email: "alice.updated@example.com", bio: "Updated" } }

    assert_redirected_to profile_url
    assert_equal "Alice Updated", @user.reload.name
  end

  test "should keep current password when password fields are blank" do
    original_password_digest = @user.password_digest

    patch profile_url, params: {
      user: {
        name: @user.name,
        email: @user.email,
        bio: @user.bio,
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to profile_url
    assert_equal original_password_digest, @user.reload.password_digest
  end

  test "should redirect show when not signed in" do
    delete session_url

    get profile_url

    assert_redirected_to new_session_url
  end
end
