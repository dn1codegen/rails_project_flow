class RegistrationsController < ApplicationController
  before_action :redirect_if_authenticated, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_authenticated
    redirect_to root_path, notice: "You are already signed in." if logged_in?
  end

  def user_params
    params.expect(user: %i[name email bio password password_confirmation])
  end
end
