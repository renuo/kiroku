# frozen_string_literal: true

Slack::Web::Client.configure do |config|
  config.token = Rails.application.credentials.dig(:slack, :bot_token) || ENV.fetch("SLACK_BOT_TOKEN", nil)
end
