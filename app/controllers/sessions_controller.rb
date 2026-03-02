class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: %i[new create]

  def new
  end

  def create
    user = User.find_by(email: params.dig(:session, :email).to_s.downcase.strip)

    if user&.authenticate(params.dig(:session, :password))
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Wrong email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out."
  end

  private

  def redirect_if_authenticated
    redirect_to root_path, notice: "You are already signed in." if logged_in?
  end
end
