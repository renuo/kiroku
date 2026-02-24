# frozen_string_literal: true

module Slack
  class EventsController < ActionController::API
    before_action :verify_slack_signature

    def create
      body = request_body

      if body["type"] == "url_verification"
        render json: { challenge: body["challenge"] }
        return
      end

      process_event_callback(body) if body["type"] == "event_callback"
      head :ok
    end

    private

    def process_event_callback(body)
      event_id = body["event_id"]
      return if Rails.cache.read("slack_event:#{event_id}")

      Rails.cache.write("slack_event:#{event_id}", true, expires_in: 1.hour)
      handle_event(body["event"])
    end

    def handle_event(event)
      return unless processable_event?(event)

      enqueue_file_jobs(event)
    end

    def processable_event?(event)
      return false unless event
      return false unless event["type"] == "message"
      return false if event["bot_id"].present?
      return false if event["subtype"].present? && event["subtype"] != "file_share"

      event["files"].present?
    end

    def enqueue_file_jobs(event)
      event["files"].each do |file|
        SlackReceiptJob.perform_later(
          slack_user_id: event["user"],
          channel_id: event["channel"],
          file_info: file.slice("id", "name", "mimetype", "filetype", "url_private_download", "size"),
          message_text: event["text"].to_s
        )
      end
    end

    def verify_slack_signature
      timestamp = request.headers["X-Slack-Request-Timestamp"]
      raw_body = request_body_raw

      Rails.logger.info "[Slack] timestamp=#{timestamp.inspect} body_length=#{raw_body.length} " \
                        "signature=#{request.headers["X-Slack-Signature"].to_s[0..10]}... " \
                        "secret_present=#{slack_signing_secret.present?}"

      if timestamp.blank? || (Time.now.to_i - timestamp.to_i).abs > 300
        Rails.logger.info "[Slack] Rejected: timestamp blank or too old (diff=#{(Time.now.to_i - timestamp.to_i).abs}s)"
        head :unauthorized
        return
      end

      head :unauthorized unless valid_signature?(timestamp, raw_body)
    end

    def valid_signature?(timestamp, raw_body)
      sig_basestring = "v0:#{timestamp}:#{raw_body}"
      expected = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", slack_signing_secret, sig_basestring)}"

      match = ActiveSupport::SecurityUtils.secure_compare(expected, request.headers["X-Slack-Signature"].to_s)
      Rails.logger.info "[Slack] Signature match=#{match}" unless match
      match
    end

    def slack_signing_secret
      @slack_signing_secret ||= begin
        from_creds = Rails.application.credentials.dig(:slack, :signing_secret)
        from_env = ENV.fetch("SLACK_SIGNING_SECRET", nil)
        Rails.logger.info "[Slack] Secret source: #{from_creds.present? ? "credentials" : "env"}"
        from_creds || from_env
      end
    end

    def request_body
      @request_body ||= JSON.parse(request_body_raw)
    end

    def request_body_raw
      @request_body_raw ||= request.raw_post
    end
  end
end
