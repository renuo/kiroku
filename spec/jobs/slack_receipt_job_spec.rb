# frozen_string_literal: true

require "rails_helper"

RSpec.describe SlackReceiptJob do
  let(:user) { create(:user, :with_slack) }
  let(:slack_client) { instance_double(Slack::Web::Client) }
  let(:file_info) do
    {
      "id" => "F123",
      "name" => "receipt.jpg",
      "mimetype" => "image/jpeg",
      "filetype" => "jpg",
      "url_private_download" => "https://files.slack.com/files-pri/T123/receipt.jpg",
      "size" => 500_000
    }
  end

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(slack_client).to receive(:token).and_return("xoxb-test")
    allow(slack_client).to receive(:chat_postMessage)

    stub_request(:get, file_info["url_private_download"])
      .to_return(
        body: Rails.root.join("spec/fixtures/files/test_receipt.jpg").binread,
        status: 200
      )
  end

  describe "#perform" do
    it "creates a receipt for a known user" do
      expect do
        described_class.new.perform(
          slack_user_id: user.slack_uid,
          channel_id: "C123",
          file_info: file_info,
          message_text: ""
        )
      end.to change(Receipt, :count).by(1)

      expect(slack_client).to have_received(:chat_postMessage)
        .with(hash_including(channel: "C123"))
    end

    it "auto-creates a user when email is not in the system" do
      allow(slack_client).to receive(:users_info)
        .and_return({
          "user" => {
            "profile" => { "email" => "brand_new@example.com", "real_name" => "Brand New User" },
            "real_name" => "Brand New User"
          }
        })

      expect do
        described_class.new.perform(
          slack_user_id: "U_NEW_USER",
          channel_id: "C123",
          file_info: file_info,
          message_text: ""
        )
      end.to change(User, :count).by(1).and change(Receipt, :count).by(1)

      new_user = User.find_by(email: "brand_new@example.com")
      expect(new_user.slack_uid).to eq("U_NEW_USER")
      expect(new_user.name).to eq("Brand New User")
    end

    it "links slack_uid to existing user matched by email" do
      existing_user = create(:user, email: "existing@example.com")
      allow(slack_client).to receive(:users_info)
        .and_return({
          "user" => {
            "profile" => { "email" => "existing@example.com", "real_name" => "Existing User" },
            "real_name" => "Existing User"
          }
        })

      expect do
        described_class.new.perform(
          slack_user_id: "U_LINK",
          channel_id: "C123",
          file_info: file_info,
          message_text: ""
        )
      end.not_to change(User, :count)

      expect(existing_user.reload.slack_uid).to eq("U_LINK")
    end

    it "notifies when Slack user has no email" do
      allow(slack_client).to receive(:users_info)
        .and_return({ "user" => { "profile" => { "email" => nil } } })

      described_class.new.perform(
        slack_user_id: "U_NO_EMAIL",
        channel_id: "C123",
        file_info: file_info,
        message_text: ""
      )

      expect(slack_client).to have_received(:chat_postMessage)
        .with(hash_including(text: /email/))
    end

    it "rejects invalid file types" do
      invalid_file_info = file_info.merge("name" => "document.txt")

      described_class.new.perform(
        slack_user_id: user.slack_uid,
        channel_id: "C123",
        file_info: invalid_file_info,
        message_text: ""
      )

      expect(slack_client).to have_received(:chat_postMessage)
        .with(hash_including(text: /Invalid file type/))
    end

    it "rejects files that are too large" do
      large_file_info = file_info.merge("size" => 11.megabytes)

      described_class.new.perform(
        slack_user_id: user.slack_uid,
        channel_id: "C123",
        file_info: large_file_info,
        message_text: ""
      )

      expect(slack_client).to have_received(:chat_postMessage)
        .with(hash_including(text: /too large/))
    end

    it "parses spent_on from message text with ISO format" do
      described_class.new.perform(
        slack_user_id: user.slack_uid,
        channel_id: "C123",
        file_info: file_info,
        message_text: "Lunch receipt 2026-01-15"
      )

      expect(Receipt.last.spent_on).to eq(Date.new(2026, 1, 15))
    end

    it "parses spent_on from message text with dot format" do
      described_class.new.perform(
        slack_user_id: user.slack_uid,
        channel_id: "C123",
        file_info: file_info,
        message_text: "Dinner 15.01.2026"
      )

      expect(Receipt.last.spent_on).to eq(Date.new(2026, 1, 15))
    end

    it "leaves spent_on nil when no date in message" do
      described_class.new.perform(
        slack_user_id: user.slack_uid,
        channel_id: "C123",
        file_info: file_info,
        message_text: "Just a receipt"
      )

      expect(Receipt.last.spent_on).to be_nil
    end
  end
end
