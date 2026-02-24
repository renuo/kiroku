# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:google_uid).allow_nil }
    it { is_expected.to validate_uniqueness_of(:slack_uid).allow_nil }
  end

  describe "associations" do
    it { is_expected.to have_many(:receipts).dependent(:destroy) }
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        uid: "new_google_uid",
        info: {
          email: "new@example.com",
          name: "New User",
          image: "https://example.com/new.jpg"
        }
      )
    end

    it "creates a new user" do
      expect { described_class.from_omniauth(auth) }.to change(described_class, :count).by(1)

      user = described_class.last
      expect(user.email).to eq("new@example.com")
      expect(user.name).to eq("New User")
      expect(user.google_uid).to eq("new_google_uid")
    end

    it "finds an existing user" do
      existing = create(:user)
      auth = OmniAuth::AuthHash.new(
        uid: existing.google_uid,
        info: {
          email: existing.email,
          name: existing.name,
          image: existing.avatar_url
        }
      )

      expect { described_class.from_omniauth(auth) }.not_to change(described_class, :count)
      expect(described_class.from_omniauth(auth).id).to eq(existing.id)
    end
  end

  describe ".find_or_create_from_slack" do
    it "links slack_uid to an existing user by email" do
      user = create(:user, email: "test@example.com")
      result = described_class.find_or_create_from_slack(slack_uid: "U12345", email: "test@example.com", name: "Test")
      expect(result).to eq(user)
      expect(user.reload.slack_uid).to eq("U12345")
    end

    it "creates a new user when email is not found" do
      result = described_class.find_or_create_from_slack(
        slack_uid: "U12345", email: "new@example.com", name: "New Slack User"
      )
      expect(result).to be_persisted
      expect(result.email).to eq("new@example.com")
      expect(result.name).to eq("New Slack User")
      expect(result.slack_uid).to eq("U12345")
      expect(result.google_uid).to be_nil
    end
  end

  describe "#admin?" do
    it "defaults to false" do
      user = create(:user)
      expect(user).not_to be_admin
    end
  end
end
