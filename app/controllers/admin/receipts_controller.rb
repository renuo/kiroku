# frozen_string_literal: true

module Admin
  class ReceiptsController < ApplicationController
    before_action :authorize_admin!
    before_action :set_receipt, only: %i[edit update destroy record unrecord]

    def index
      @receipts = filtered_receipts.page(params[:page]).per(30)
      @grouped_receipts = @receipts.group_by { |r| r.effective_date.beginning_of_month }
      @users = User.order(:name)
    end

    def new
      @receipt = Receipt.new
      @users = User.order(:name)
    end

    def edit
      @users = User.order(:name)
    end

    def create
      @receipt = Receipt.new(admin_receipt_params)

      if @receipt.save
        redirect_to admin_receipts_path, notice: t("success", scope: "admin.receipts.create")
      else
        @users = User.order(:name)
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @receipt.update(admin_receipt_params)
        redirect_to admin_receipts_path, notice: t("success", scope: "admin.receipts.update")
      else
        @users = User.order(:name)
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @receipt.destroy
      redirect_to admin_receipts_path, notice: t("success", scope: "admin.receipts.destroy")
    end

    def record
      if params[:code].present?
        @receipt.update!(code: params[:code], recorded_on: Time.current)
        redirect_to admin_receipts_path, notice: t("success", scope: "admin.receipts.record")
      else
        redirect_to admin_receipts_path, alert: t("error", scope: "admin.receipts.record")
      end
    end

    def unrecord
      @receipt.update!(code: nil, recorded_on: nil)
      redirect_to admin_receipts_path, notice: t("success", scope: "admin.receipts.unrecord")
    end

    private

    def set_receipt
      @receipt = Receipt.find(params[:id])
    end

    def filtered_receipts
      receipts = Receipt.includes(:user).ordered
      receipts = receipts.by_user(params[:user_id]) if params[:user_id].present?
      receipts
    end

    def admin_receipt_params
      params.expect(receipt: %i[user_id file spent_on])
    end
  end
end
