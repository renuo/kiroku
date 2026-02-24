# frozen_string_literal: true

class ReceiptFilesController < ApplicationController
  def show
    send_file receipt.file.path, disposition: :inline
  end

  def preview
    send_file receipt.file.preview.path, disposition: :inline
  end

  private

  def receipt
    @receipt ||= receipt_scope.find(params[:receipt_id])
  end

  def receipt_scope
    current_user.admin? ? Receipt : current_user.receipts
  end
end
