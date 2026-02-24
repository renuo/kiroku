# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions" do
  describe "POST /auth/google_oauth2/callback" do
    it "signs in an existing user" do
      user = create(:user)
      sign_in(user)

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(user.id)
    end

    it "creates a new user if not found" do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "brand_new_uid",
        info: {
          email: "brand_new@example.com",
          name: "Brand New",
          image: "https://example.com/new.jpg"
        }
      )

      expect { get "/auth/google_oauth2/callback" }.to change(User, :count).by(1)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /sign_out" do
    it "clears the session" do
      user = create(:user)
      sign_in(user)

      delete sign_out_path
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "GET /auth/failure" do
    it "redirects with alert" do
      get "/auth/failure"
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Authentication failed. Please try again.")
    end
  end
end
