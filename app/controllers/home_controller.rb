# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    if current_user&.admin?
      redirect_to admin_receipts_path
    elsif user_signed_in?
      redirect_to new_receipt_path
    end
  end
end
