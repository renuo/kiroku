# frozen_string_literal: true

require "rails_helper"

RSpec.describe Slack::EventsController do
  let(:signing_secret) { "test_signing_secret" }
  let(:timestamp) { Time.now.to_i.to_s }

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig)
      .with(:slack, :signing_secret).and_return(signing_secret)
    allow(Rails.application.credentials).to receive(:dig)
      .with(:slack, :bot_token).and_return("xoxb-test")
  end

  def slack_signature(body)
    sig_basestring = "v0:#{timestamp}:#{body}"
    "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)}"
  end

  def slack_headers(body)
    {
      "X-Slack-Request-Timestamp" => timestamp,
      "X-Slack-Signature" => slack_signature(body),
      "Content-Type" => "application/json"
    }
  end

  describe "POST /slack/events" do
    it "responds to URL verification challenge" do
      body = { type: "url_verification", challenge: "abc123" }.to_json

      post "/slack/events", params: body, headers: slack_headers(body)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["challenge"]).to eq("abc123")
    end

    it "rejects requests with invalid signatures" do
      body = { type: "url_verification", challenge: "abc123" }.to_json

      post "/slack/events", params: body, headers: {
        "X-Slack-Request-Timestamp" => timestamp,
        "X-Slack-Signature" => "v0=invalid",
        "Content-Type" => "application/json"
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with missing timestamp" do
      body = { type: "url_verification", challenge: "abc123" }.to_json

      post "/slack/events", params: body, headers: {
        "X-Slack-Signature" => "v0=something",
        "Content-Type" => "application/json"
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "enqueues a job for file messages" do
      body = {
        type: "event_callback",
        event_id: "Ev123",
        event: {
          type: "message",
          user: "U12345",
          channel: "C12345",
          text: "Here is a receipt",
          files: [{
            id: "F123",
            name: "receipt.jpg",
            mimetype: "image/jpeg",
            filetype: "jpg",
            url_private_download: "https://files.slack.com/receipt.jpg",
            size: 500_000
          }]
        }
      }.to_json

      expect do
        post "/slack/events", params: body, headers: slack_headers(body)
      end.to have_enqueued_job(SlackReceiptJob)

      expect(response).to have_http_status(:ok)
    end

    it "ignores bot messages" do
      body = {
        type: "event_callback",
        event_id: "Ev456",
        event: {
          type: "message",
          bot_id: "B123",
          user: "U12345",
          channel: "C12345",
          text: "Bot message",
          files: [{ id: "F123", name: "receipt.jpg" }]
        }
      }.to_json

      expect do
        post "/slack/events", params: body, headers: slack_headers(body)
      end.not_to have_enqueued_job(SlackReceiptJob)
    end

    it "ignores messages without files" do
      body = {
        type: "event_callback",
        event_id: "Ev789",
        event: {
          type: "message",
          user: "U12345",
          channel: "C12345",
          text: "Just a message"
        }
      }.to_json

      expect do
        post "/slack/events", params: body, headers: slack_headers(body)
      end.not_to have_enqueued_job(SlackReceiptJob)
    end

    it "deduplicates events with the same event_id" do
      body = {
        type: "event_callback",
        event_id: "Ev_dedup",
        event: {
          type: "message",
          user: "U12345",
          channel: "C12345",
          text: "Receipt",
          files: [{
            id: "F123",
            name: "receipt.jpg",
            mimetype: "image/jpeg",
            filetype: "jpg",
            url_private_download: "https://files.slack.com/receipt.jpg",
            size: 500_000
          }]
        }
      }.to_json

      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      post "/slack/events", params: body, headers: slack_headers(body)
      expect do
        post "/slack/events", params: body, headers: slack_headers(body)
      end.not_to have_enqueued_job(SlackReceiptJob)
    end
  end
end
