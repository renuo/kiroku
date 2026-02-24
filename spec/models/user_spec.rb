# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:google_uid) }
    it { is_expected.to validate_uniqueness_of(:google_uid) }
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

  describe "#admin?" do
    it "defaults to false" do
      user = create(:user)
      expect(user).not_to be_admin
    end
  end
end
