# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ReceiptFiles" do
  let(:user) { create(:user) }
  let(:receipt) { create(:receipt, user: user) }

  describe "GET /receipts/:receipt_id/file" do
    context "when authenticated as the owner" do
      before { sign_in(user) }

      it "serves the file" do
        get receipt_file_path(receipt)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }

      before { sign_in(other_user) }

      it "returns not found" do
        get receipt_file_path(receipt)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as admin" do
      let(:admin) { create(:user, :admin) }

      before { sign_in(admin) }

      it "serves any user's file" do
        get receipt_file_path(receipt)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to root" do
        get receipt_file_path(receipt)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /receipts/:receipt_id/file/preview" do
    before { sign_in(user) }

    it "serves the preview file" do
      get preview_receipt_file_path(receipt)
      expect(response).to have_http_status(:success)
    end
  end
end
