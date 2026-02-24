# frozen_string_literal: true

module AuthenticationHelpers
  def sign_in(user)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: user.google_uid,
      info: {
        email: user.email,
        name: user.name,
        image: user.avatar_url
      }
    )
    get "/auth/google_oauth2/callback"
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
