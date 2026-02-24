# frozen_string_literal: true

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.before do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
