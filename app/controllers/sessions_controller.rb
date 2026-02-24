# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    user = User.from_omniauth(request.env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to root_path, notice: t("success", scope: "sessions.create")
  end

  def destroy
    reset_session
    redirect_to root_path, notice: t("success", scope: "sessions.destroy")
  end

  def failure
    redirect_to root_path, alert: t("error", scope: "sessions.failure")
  end
end
