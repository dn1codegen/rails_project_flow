class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @active_share_projects = active_share_projects_scope.to_a
    @query = params[:q].to_s.strip
    @show_recent_projects = @query.blank?
    @selected_year = params[:year].to_s.strip
    @selected_month = params[:month].to_s.strip
    @archive_years = @user.projects.order(created_at: :desc).pluck(:created_at).map(&:year).uniq
    @archive_months = []
    projects_scope = @user.projects.includes(:project_changes, { cover_image_attachment: :blob }).order(created_at: :desc)
    @projects = projects_scope

    if @selected_year.match?(/\A\d{4}\z/)
      year = @selected_year.to_i
      year_range = Time.zone.local(year, 1, 1).all_year
      @projects = @projects.where(created_at: year_range)
      @archive_months = @user.projects.where(created_at: year_range).order(created_at: :desc).pluck(:created_at).map(&:month).uniq

      if @selected_month.match?(/\A(0?[1-9]|1[0-2])\z/)
        month = @selected_month.to_i
        @selected_month = month.to_s
        @projects = @projects.where(created_at: Time.zone.local(year, month, 1).all_month)
      else
        @selected_month = ""
      end
    else
      @selected_year = ""
      @selected_month = ""
    end

    unless @query.present?
      @projects =
        @projects
          .select { |project| project.project_changes.any? }
          .sort_by { |project| project.project_changes.first.changed_at }
          .reverse
          .first(10)
      return
    end

    query_terms = @query.split(/\s+/).map { |term| normalize_profile_search_text(term) }.reject(&:blank?)
    @projects = @projects.to_a.select { |project| profile_project_matches_query_terms?(project, query_terms) }
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    filtered_params = params.expect(user: %i[name email bio password password_confirmation])

    if filtered_params[:password].blank?
      filtered_params.except(:password, :password_confirmation)
    else
      filtered_params
    end
  end

  def profile_project_matches_query_terms?(project, query_terms)
    searchable_values = [
      project.product,
      project.title,
      project.description,
      project.customer_name,
      project.address,
      project.place,
      project.status,
      project.user&.name,
      project.user&.email
    ].map { |value| normalize_profile_search_text(value) }

    query_terms.all? do |term|
      searchable_values.any? { |value| value.include?(term) }
    end
  end

  def normalize_profile_search_text(value)
    value.to_s.downcase
  end

  def active_share_projects_scope
    @user
      .projects
      .where.not(share_token: nil)
      .where("share_token_expires_at > ?", Time.current)
      .order(share_token_expires_at: :asc, created_at: :desc)
  end
end
