# frozen_string_literal: true

require "rails_helper"

RSpec.describe Receipt do
  describe "validations" do
    it "is valid with a file attached" do
      receipt = build(:receipt)
      expect(receipt).to be_valid
    end

    it "requires a file" do
      receipt = described_class.new(user: build(:user))
      expect(receipt).not_to be_valid
      expect(receipt.errors[:file]).to include("must be attached")
    end

    it { is_expected.to belong_to(:user) }

    it "validates file extension" do
      receipt = build(:receipt)
      tempfile = Tempfile.new(["test", ".txt"])
      tempfile.write("not an image")
      tempfile.rewind
      receipt.file = Rack::Test::UploadedFile.new(tempfile.path, "text/plain")
      expect(receipt).not_to be_valid
    ensure
      tempfile&.close!
    end

    it "accepts jpeg files" do
      receipt = build(:receipt)
      receipt.file = uploaded_receipt_file(content_type: "image/jpeg")
      expect(receipt).to be_valid
    end

    it "accepts pdf files" do
      receipt = build(:receipt)
      receipt.file = uploaded_receipt_file(content_type: "application/pdf", filename: "test_receipt.pdf")
      expect(receipt).to be_valid
    end
  end

  describe "#effective_date" do
    it "returns spent_on when present" do
      receipt = build(:receipt, spent_on: Date.new(2026, 1, 15))
      expect(receipt.effective_date).to eq(Date.new(2026, 1, 15))
    end

    it "returns created_at date when spent_on is nil" do
      receipt = create(:receipt, spent_on: nil)
      expect(receipt.effective_date).to eq(receipt.created_at.to_date)
    end
  end

  describe "#recorded?" do
    it "returns true when recorded_on is set" do
      receipt = build(:receipt, :recorded)
      expect(receipt).to be_recorded
    end

    it "returns false when recorded_on is nil" do
      receipt = build(:receipt)
      expect(receipt).not_to be_recorded
    end
  end

  describe "#image_file?" do
    it "returns true for image extensions" do
      receipt = build(:receipt)
      expect(receipt).to be_image_file
    end

    it "returns false for pdf files" do
      receipt = build(:receipt)
      receipt.file = uploaded_receipt_file(content_type: "application/pdf", filename: "test_receipt.pdf")
      expect(receipt).not_to be_image_file
    end
  end

  describe "#pdf_file?" do
    it "returns true for pdf files" do
      receipt = build(:receipt)
      receipt.file = uploaded_receipt_file(content_type: "application/pdf", filename: "test_receipt.pdf")
      expect(receipt).to be_pdf_file
    end

    it "returns false for image files" do
      receipt = build(:receipt)
      expect(receipt).not_to be_pdf_file
    end
  end

  describe "scopes" do
    before do
      create(:receipt, :recorded)
      create(:receipt)
    end

    describe ".recorded" do
      it "returns only recorded receipts" do
        expect(described_class.recorded).to all(be_recorded)
      end
    end

    describe ".unrecorded" do
      it "returns only unrecorded receipts" do
        expect(described_class.unrecorded.map(&:recorded?)).to all(be(false))
      end
    end

    describe ".by_user" do
      it "filters by user" do
        user = create(:user)
        create(:receipt, user: user)
        create(:receipt)

        receipts = described_class.by_user(user.id)
        expect(receipts).to all(have_attributes(user_id: user.id))
      end
    end
  end
end
