# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Receipts" do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before { sign_in(admin) }

  describe "GET /admin/receipts" do
    it "shows all receipts for admin" do
      get admin_receipts_path
      expect(response).to have_http_status(:success)
    end

    it "renders receipts when they exist" do
      create(:receipt, user: regular_user)

      get admin_receipts_path
      expect(response).to have_http_status(:success)
    end

    it "filters by user" do
      get admin_receipts_path(user_id: regular_user.id)
      expect(response).to have_http_status(:success)
    end

    it "is denied for non-admin" do
      reset!
      sign_in(regular_user)
      get admin_receipts_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/receipts/new" do
    it "shows upload form" do
      get new_admin_receipt_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/receipts" do
    it "uploads receipt for another user" do
      file = fixture_file_upload("test_receipt.jpg", "image/jpeg")

      expect do
        post admin_receipts_path, params: { receipt: { user_id: regular_user.id, file: file, spent_on: "2026-01-15" } }
      end.to change(Receipt, :count).by(1)

      expect(response).to redirect_to(admin_receipts_path)
      expect(Receipt.last.user_id).to eq(regular_user.id)
    end
  end

  describe "GET /admin/receipts/:id/edit" do
    it "shows form" do
      receipt = create(:receipt, user: regular_user)

      get edit_admin_receipt_path(receipt)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/receipts/:id" do
    it "changes receipt" do
      receipt = create(:receipt, user: regular_user)

      patch admin_receipt_path(receipt), params: { receipt: { spent_on: "2026-03-01" } }
      expect(response).to redirect_to(admin_receipts_path)
      expect(receipt.reload.spent_on).to eq(Date.new(2026, 3, 1))
    end
  end

  describe "DELETE /admin/receipts/:id" do
    it "deletes receipt" do
      receipt = create(:receipt, user: regular_user)

      expect { delete admin_receipt_path(receipt) }.to change(Receipt, :count).by(-1)
      expect(response).to redirect_to(admin_receipts_path)
    end

    it "can delete recorded receipt" do
      receipt = create(:receipt, :recorded, user: regular_user)

      expect { delete admin_receipt_path(receipt) }.to change(Receipt, :count).by(-1)
    end
  end

  describe "PATCH /admin/receipts/:id/record" do
    it "marks receipt as recorded with code" do
      receipt = create(:receipt, user: regular_user)

      patch record_admin_receipt_path(receipt), params: { code: "BK-100" }
      expect(response).to redirect_to(admin_receipts_path)

      receipt.reload
      expect(receipt).to be_recorded
      expect(receipt.code).to eq("BK-100")
    end

    it "requires code" do
      receipt = create(:receipt, user: regular_user)

      patch record_admin_receipt_path(receipt), params: { code: "" }
      expect(response).to redirect_to(admin_receipts_path)
      expect(flash[:alert]).to eq("Code is required to record a receipt.")
    end
  end

  describe "PATCH /admin/receipts/:id/unrecord" do
    it "clears recorded status" do
      receipt = create(:receipt, :recorded, user: regular_user)

      patch unrecord_admin_receipt_path(receipt)
      expect(response).to redirect_to(admin_receipts_path)

      receipt.reload
      expect(receipt).not_to be_recorded
      expect(receipt.code).to be_nil
    end
  end
end
