# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Receipts" do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /receipts" do
    it "shows user receipts" do
      get receipts_path
      expect(response).to have_http_status(:success)
    end

    it "requires authentication" do
      reset!
      get receipts_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /receipts" do
    it "uploads a receipt" do
      file = fixture_file_upload("test_receipt.jpg", "image/jpeg")

      expect { post receipts_path, params: { receipt: { file: file, spent_on: "2026-01-15" } } }
        .to change(Receipt, :count).by(1)

      expect(response).to redirect_to(new_receipt_path)
    end

    it "redirects with invalid file" do
      post receipts_path, params: { receipt: { spent_on: "2026-01-15" } }
      expect(response).to redirect_to(new_receipt_path)
    end
  end

  describe "GET /receipts/:id/edit" do
    it "shows form for own receipt" do
      receipt = create(:receipt, user: user)

      get edit_receipt_path(receipt)
      expect(response).to have_http_status(:success)
    end

    it "cannot access other user's receipt" do
      receipt = create(:receipt, :admin_owned)

      get edit_receipt_path(receipt)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /receipts/:id" do
    it "changes spent_on" do
      receipt = create(:receipt, user: user)

      patch receipt_path(receipt), params: { receipt: { spent_on: "2026-02-20" } }
      expect(response).to redirect_to(receipts_path)
      expect(receipt.reload.spent_on).to eq(Date.new(2026, 2, 20))
    end
  end

  describe "DELETE /receipts/:id" do
    it "deletes unrecorded receipt" do
      receipt = create(:receipt, user: user)

      expect { delete receipt_path(receipt) }.to change(Receipt, :count).by(-1)
      expect(response).to redirect_to(receipts_path)
    end

    it "blocks deletion of recorded receipt" do
      receipt = create(:receipt, :recorded, user: user)

      expect { delete receipt_path(receipt) }.not_to change(Receipt, :count)
      expect(response).to redirect_to(receipts_path)
      expect(flash[:alert]).to eq("Cannot delete a recorded receipt.")
    end
  end
end
