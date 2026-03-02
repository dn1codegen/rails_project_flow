class ProjectsController < ApplicationController
  ATTACHMENT_FIELDS = %i[measurement_images example_files installation_photos].freeze
  ATTACHMENT_DESCRIPTION_PARAM = :attachment_descriptions

  before_action :require_login, except: %i[index show]
  before_action :set_project, only: %i[show edit update]
  before_action :require_project_owner, only: %i[edit update]

  def index
    @projects = Project.includes(:user, :project_changes).order(created_at: :desc)
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
    base_attributes = project_attributes.except(*ATTACHMENT_FIELDS, ATTACHMENT_DESCRIPTION_PARAM)

    if @project.update(base_attributes)
      attach_project_files(@project, project_attributes)
      update_attachment_descriptions(@project, project_attributes[ATTACHMENT_DESCRIPTION_PARAM])
      redirect_to @project, notice: "Project was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project =
      if action_name.in?(%w[show edit update])
        Project.includes(
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
      measurement_images: [],
      example_files: [],
      installation_photos: [],
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
end
