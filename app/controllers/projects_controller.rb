class ProjectsController < ApplicationController
  ATTACHMENT_FIELDS = %i[measurement_images example_files installation_photos].freeze
  ATTACHMENT_DESCRIPTION_PARAM = :attachment_descriptions
  REMOVE_ATTACHMENT_IDS_PARAM = :remove_attachment_ids
  REMOVE_COVER_IMAGE_PARAM = :remove_cover_image
  PROJECT_BLOCK_DEFINITIONS = [
    { key: :month, title: "Проекты не более месяца" },
    { key: :quarter, title: "Проекты не более 3 месяцев" },
    { key: :year, title: "Проекты до года" }
  ].freeze

  before_action :require_login, except: %i[index show]
  before_action :set_project, only: %i[show edit update destroy]
  before_action :require_project_owner, only: %i[edit update destroy]

  def index
    projects = Project.includes(:user, :project_changes, { cover_image_attachment: :blob }).order(created_at: :desc)
    @project_blocks = build_project_blocks(projects)
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

  def build_project_blocks(projects, now: Time.current)
    project_entries_by_block = { month: [], quarter: [], year: [] }

    entries = projects.map do |project|
      last_changed_at = project.project_changes.first&.changed_at
      last_edited_at = last_changed_at || project.updated_at

      { project: project, last_edited_at: last_edited_at }
    end.sort_by { |entry| entry[:last_edited_at] }.reverse

    entries.each do |entry|
      age = now - entry[:last_edited_at]

      if age <= 1.month
        project_entries_by_block[:month] << entry
      elsif age <= 3.months
        project_entries_by_block[:quarter] << entry
      elsif age <= 1.year
        project_entries_by_block[:year] << entry
      else
        project_entries_by_block[:year] << entry
      end
    end

    PROJECT_BLOCK_DEFINITIONS.map do |block|
      { title: block[:title], entries: project_entries_by_block[block[:key]] }
    end
  end
end
