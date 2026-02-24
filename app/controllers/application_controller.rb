# frozen_string_literal: true

class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!

  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    return if user_signed_in?

    redirect_to root_path, alert: t("error", scope: "sessions.failure")
  end

  def authorize_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: t("error", scope: "sessions.failure")
  end
end
