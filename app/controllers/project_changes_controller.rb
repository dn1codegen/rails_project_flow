class ProjectChangesController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :require_project_owner

  def create
    @project_change = @project.project_changes.new(project_change_params)

    if @project_change.save
      redirect_to @project, notice: "Change entry added to project history."
    else
      render "projects/show", status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def require_project_owner
    require_project_owner!(@project)
  end

  def project_change_params
    params.expect(project_change: [ :description, images: [] ])
  end
end
