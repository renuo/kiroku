# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authorization" do
  let(:regular_user) { create(:user) }
  let(:admin_user) { create(:user, :admin) }

  describe "unauthenticated user" do
    it "can see home page" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "cannot access receipts" do
      get receipts_path
      expect(response).to redirect_to(root_path)
    end

    it "cannot access admin" do
      get admin_receipts_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "regular user" do
    before { sign_in(regular_user) }

    it "cannot access admin" do
      get admin_receipts_path
      expect(response).to redirect_to(root_path)
    end

    it "can access own receipts" do
      get receipts_path
      expect(response).to have_http_status(:success)
    end

    it "cannot access other user's receipts" do
      receipt = create(:receipt, :admin_owned)

      get edit_receipt_path(receipt)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot delete recorded receipt" do
      receipt = create(:receipt, :recorded, user: regular_user)

      expect { delete receipt_path(receipt) }.not_to change(Receipt, :count)
    end
  end

  describe "admin user" do
    before { sign_in(admin_user) }

    it "can access admin area" do
      get admin_receipts_path
      expect(response).to have_http_status(:success)
    end

    it "can record a receipt" do
      receipt = create(:receipt)

      patch record_admin_receipt_path(receipt), params: { code: "BK-200" }
      expect(response).to redirect_to(admin_receipts_path)
      expect(receipt.reload).to be_recorded
    end

    it "can unrecord a receipt" do
      receipt = create(:receipt, :recorded)

      patch unrecord_admin_receipt_path(receipt)
      expect(response).to redirect_to(admin_receipts_path)
      expect(receipt.reload).not_to be_recorded
    end

    it "can delete any receipt including recorded" do
      receipt = create(:receipt, :recorded)

      expect { delete admin_receipt_path(receipt) }.to change(Receipt, :count).by(-1)
    end
  end

  describe "sign in and sign out flow" do
    it "completes full authentication cycle" do
      sign_in(regular_user)
      expect(response).to redirect_to(root_path)

      get receipts_path
      expect(response).to have_http_status(:success)

      delete sign_out_path
      expect(response).to redirect_to(root_path)

      get receipts_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects regular user from root to new receipt" do
      sign_in(regular_user)
      get root_path
      expect(response).to redirect_to(new_receipt_path)
    end

    it "redirects admin from root to admin receipts" do
      sign_in(admin_user)
      get root_path
      expect(response).to redirect_to(admin_receipts_path)
    end
  end
end
