# frozen_string_literal: true

class SlackReceiptJob < ApplicationJob
  queue_as :default

  ALLOWED_EXTENSIONS = %w[jpg jpeg png heic webp pdf].freeze
  MAX_FILE_SIZE = 10.megabytes

  def perform(slack_user_id:, channel_id:, file_info:, message_text:)
    @slack_client = ::Slack::Web::Client.new
    @channel_id = channel_id

    process_receipt(slack_user_id, file_info, message_text)
  rescue FileValidationError => e
    notify_error(e.message)
  rescue StandardError => e
    Rails.logger.error("SlackReceiptJob failed: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    notify_error(I18n.t("slack.receipts.unexpected_error"))
  end

  private

  def process_receipt(slack_user_id, file_info, message_text)
    user = resolve_user(slack_user_id)
    validate_file!(file_info)
    tempfile = download_file(file_info)
    receipt = create_receipt(user: user, tempfile: tempfile, file_info: file_info,
                             spent_on: parse_spent_on(message_text))

    notify_receipt_result(receipt)
  ensure
    tempfile&.close!
  end

  def notify_receipt_result(receipt)
    if receipt.persisted?
      notify_success(receipt)
    else
      notify_error(I18n.t("save_failed", scope: "slack.receipts", errors: receipt.errors.full_messages.join(", ")))
    end
  end

  def resolve_user(slack_user_id)
    user = User.find_by(slack_uid: slack_user_id)
    return user if user

    slack_info = @slack_client.users_info(user: slack_user_id)
    email = slack_info.dig("user", "profile", "email")
    name = slack_info.dig("user", "profile", "real_name") || slack_info.dig("user", "real_name")

    raise FileValidationError, I18n.t("slack.receipts.missing_email") if email.blank?

    User.find_or_create_from_slack(slack_uid: slack_user_id, email: email, name: name)
  end

  def validate_file!(file_info)
    extension = File.extname(file_info["name"].to_s).delete(".").downcase

    unless ALLOWED_EXTENSIONS.include?(extension)
      raise FileValidationError,
            I18n.t("invalid_file_type", scope: "slack.receipts", allowed: ALLOWED_EXTENSIONS.join(", "))
    end

    return unless file_info["size"].to_i > MAX_FILE_SIZE

    raise FileValidationError, I18n.t("slack.receipts.file_too_large")
  end

  def download_file(file_info)
    tempfile = Tempfile.new(["slack_receipt", File.extname(file_info["name"].to_s)])
    tempfile.binmode

    response = Faraday.get(file_info["url_private_download"]) do |req|
      req.headers["Authorization"] = "Bearer #{@slack_client.token}"
    end

    tempfile.write(response.body)
    tempfile.rewind
    tempfile
  end

  def parse_spent_on(message_text)
    return nil if message_text.blank?

    date_patterns = [
      /(\d{4}-\d{2}-\d{2})/,
      /(\d{2}\.\d{2}\.\d{4})/,
      %r{(\d{2}/\d{2}/\d{4})}
    ]

    date_patterns.each do |pattern|
      match = message_text.match(pattern)
      next unless match

      return Date.parse(match[1])
    rescue Date::Error
      next
    end

    nil
  end

  def create_receipt(user:, tempfile:, file_info:, spent_on:)
    uploaded_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: file_info["name"],
      type: file_info["mimetype"]
    )

    receipt = user.receipts.build(spent_on: spent_on)
    receipt.file = uploaded_file
    receipt.save

    receipt
  end

  def notify_success(receipt)
    date_info = receipt.spent_on ? " (#{receipt.spent_on})" : ""
    @slack_client.chat_postMessage(
      channel: @channel_id,
      text: I18n.t("saved", scope: "slack.receipts", filename: receipt.file.file.filename, date: date_info)
    )
  end

  def notify_error(message)
    @slack_client.chat_postMessage(channel: @channel_id, text: message)
  rescue StandardError => e
    Rails.logger.error("Failed to send Slack error notification: #{e.message}")
  end

  class FileValidationError < StandardError; end
end
