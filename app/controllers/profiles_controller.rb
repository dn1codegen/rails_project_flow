class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @projects = @user.projects.includes(:project_changes, { cover_image_attachment: :blob }).order(created_at: :desc)
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
end
