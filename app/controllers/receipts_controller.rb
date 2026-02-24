# frozen_string_literal: true

class ReceiptsController < ApplicationController
  before_action :set_receipt, only: %i[edit update destroy]

  def index
    @receipts = current_user.receipts.ordered.page(params[:page]).per(20)
    @grouped_receipts = @receipts.group_by { |r| r.effective_date.beginning_of_month }
  end

  def new
    @receipt = Receipt.new
  end

  def edit; end

  def create
    @receipt = current_user.receipts.build(receipt_params)

    if @receipt.save
      redirect_to new_receipt_path, notice: t("success", scope: "receipts.create")
    else
      redirect_to new_receipt_path, alert: @receipt.errors.full_messages.join(", ")
    end
  end

  def update
    if @receipt.update(receipt_update_params)
      redirect_to receipts_path, notice: t("success", scope: "receipts.update")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @receipt.recorded?
      redirect_to receipts_path, alert: t("cannot_delete_recorded", scope: "receipts.destroy")
    else
      @receipt.destroy
      redirect_to receipts_path, notice: t("success", scope: "receipts.destroy")
    end
  end

  private

  def set_receipt
    @receipt = current_user.receipts.find(params[:id])
  end

  def receipt_params
    params.expect(receipt: %i[file spent_on])
  end

  def receipt_update_params
    params.expect(receipt: [:spent_on])
  end
end
