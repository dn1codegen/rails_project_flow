class SharedProjectsController < ApplicationController
  layout "shared_project"

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def show
    @shared_view = true
    @project =
      Project.includes(
        { cover_image_attachment: :blob },
        { measurement_images_attachments: :blob },
        { example_files_attachments: :blob },
        { installation_photos_attachments: :blob },
        { project_changes: [ images_attachments: :blob ] },
        :project_attachment_descriptions
      ).find_by!(
        share_token: params[:token]
      )
    return render_not_found unless @project.active_share_link?

    render "projects/show"
  end

  private

  def render_not_found
    head :not_found
  end
end
