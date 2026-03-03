class ProjectsController < ApplicationController
  ATTACHMENT_FIELDS = %i[measurement_images example_files installation_photos].freeze
  ATTACHMENT_DESCRIPTION_PARAM = :attachment_descriptions
  REMOVE_ATTACHMENT_IDS_PARAM = :remove_attachment_ids
  REMOVE_COVER_IMAGE_PARAM = :remove_cover_image
  PROJECT_BLOCK_TITLE = "Последние отредактированные проекты".freeze
  INDEX_LIMIT_OPTIONS = [ 10, 30, 70, 100 ].freeze
  DEFAULT_INDEX_LIMIT = 10

  before_action :require_login, except: %i[index archive show]
  before_action :set_project, only: %i[show edit update destroy refresh_share_link]
  before_action :require_project_owner, only: %i[edit update destroy refresh_share_link]

  def index
    @index_limit_options = INDEX_LIMIT_OPTIONS
    @selected_index_limit = selected_index_limit
    projects = Project.includes(:user, :project_changes, { cover_image_attachment: :blob }).order(created_at: :desc)
    @project_blocks = build_project_blocks(projects, limit: @selected_index_limit)
  end

  def archive
    @query = params[:q].to_s.strip
    @selected_year = params[:year].to_s.strip
    @selected_month = params[:month].to_s.strip
    @archive_years = Project.order(created_at: :desc).pluck(:created_at).map(&:year).uniq
    @archive_months = []
    @projects =
      Project.left_joins(:user)
        .includes(:user, :project_changes)
        .order(created_at: :desc)

    if @selected_year.match?(/\A\d{4}\z/)
      year = @selected_year.to_i
      year_range = Time.zone.local(year, 1, 1).all_year
      @projects = @projects.where(created_at: year_range)
      @archive_months = Project.where(created_at: year_range).order(created_at: :desc).pluck(:created_at).map(&:month).uniq

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
      @projects = Project.none
      return
    end

    query_terms = @query.split(/\s+/).map { |term| normalize_archive_search_text(term) }.reject(&:blank?)
    @projects = @projects.to_a.select { |project| archive_project_matches_query_terms?(project, query_terms) }
  end

  def show
    @project_change = ProjectChange.new
  end

  def new
    @project = current_user.projects.new
  end

  def create
    @project = current_user.projects.new(project_params)

    if @project.save
      redirect_to @project, notice: "Project was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    project_attributes = project_params
    base_attributes =
      project_attributes.except(
        *ATTACHMENT_FIELDS,
        ATTACHMENT_DESCRIPTION_PARAM,
        REMOVE_ATTACHMENT_IDS_PARAM,
        REMOVE_COVER_IMAGE_PARAM
      )

    if @project.update(base_attributes)
      purge_cover_image(@project, project_attributes[REMOVE_COVER_IMAGE_PARAM])
      purge_project_files(@project, project_attributes[REMOVE_ATTACHMENT_IDS_PARAM])
      attach_project_files(@project, project_attributes)
      update_attachment_descriptions(@project, project_attributes[ATTACHMENT_DESCRIPTION_PARAM])
      redirect_to @project, notice: "Project was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project was deleted."
  end

  def refresh_share_link
    @project.regenerate_share_link!
    redirect_to @project, notice: "Share link is active for 4 days."
  end

  private

  def set_project
    @project =
      if action_name.in?(%w[show edit update])
        Project.includes(
          { cover_image_attachment: :blob },
          { measurement_images_attachments: :blob },
          { example_files_attachments: :blob },
          { installation_photos_attachments: :blob },
          { project_changes: [ images_attachments: :blob ] },
          :project_attachment_descriptions
        ).find(params[:id])
      else
        Project.find(params[:id])
      end
  end

  def require_project_owner
    require_project_owner!(@project)
  end

  def project_params
    params.require(:project).permit(
      :description,
      :customer_name,
      :address,
      :place,
      :product,
      :status,
      :cover_image,
      :remove_cover_image,
      measurement_images: [],
      example_files: [],
      installation_photos: [],
      remove_attachment_ids: [],
      attachment_descriptions: {}
    )
  end

  def attach_project_files(project, project_attributes)
    ATTACHMENT_FIELDS.each do |field|
      files = Array(project_attributes[field]).reject(&:blank?)
      next if files.empty?

      project.public_send(field).attach(files)
    end
  end

  def purge_cover_image(project, remove_cover_image)
    return unless ActiveModel::Type::Boolean.new.cast(remove_cover_image)
    return unless project.cover_image.attached?

    project.cover_image.purge
  end

  def purge_project_files(project, attachment_ids)
    ids = Array(attachment_ids).reject(&:blank?).map(&:to_i)
    return if ids.empty?

    attachments_by_id = project_attachments_index(project)

    ids.each do |attachment_id|
      attachment = attachments_by_id[attachment_id]
      next unless attachment

      project.project_attachment_descriptions.find_by(attachment_id: attachment.id)&.destroy
      attachment.purge
    end
  end

  def update_attachment_descriptions(project, descriptions_by_attachment_id)
    return if descriptions_by_attachment_id.blank?

    attachments_by_id = project_attachments_index(project)

    descriptions_by_attachment_id.each do |attachment_id, description|
      attachment = attachments_by_id[attachment_id.to_i]
      next unless attachment

      cleaned_description = description.to_s.strip
      existing_description = project.project_attachment_descriptions.find do |item|
        item.attachment_id == attachment.id
      end

      if cleaned_description.blank?
        existing_description&.destroy
      elsif existing_description
        existing_description.update(description: cleaned_description)
      else
        project.project_attachment_descriptions.create(
          attachment: attachment,
          description: cleaned_description
        )
      end
    end
  end

  def project_attachments_index(project)
    (
      project.measurement_images.attachments +
      project.example_files.attachments +
      project.installation_photos.attachments
    ).index_by(&:id)
  end

  def build_project_blocks(projects, now: Time.current, limit:)
    entries = projects.map do |project|
      last_edited_at = project.project_changes.first&.changed_at || project.created_at

      { project: project, last_edited_at: last_edited_at }
    end.sort_by { |entry| entry[:last_edited_at] }.reverse

    recent_entries = entries.select { |entry| now - entry[:last_edited_at] <= 1.year }.first(limit)
    [ { title: PROJECT_BLOCK_TITLE, entries: recent_entries } ]
  end

  def selected_index_limit
    requested_limit = params[:limit].to_i
    INDEX_LIMIT_OPTIONS.include?(requested_limit) ? requested_limit : DEFAULT_INDEX_LIMIT
  end

  def archive_project_matches_query_terms?(project, query_terms)
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
    ].map { |value| normalize_archive_search_text(value) }

    query_terms.all? do |term|
      searchable_values.any? { |value| value.include?(term) }
    end
  end

  def normalize_archive_search_text(value)
    value.to_s.downcase
  end
end
