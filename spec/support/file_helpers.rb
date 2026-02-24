# frozen_string_literal: true

module FileHelpers
  def uploaded_receipt_file(content_type: "image/jpeg", filename: "test_receipt.jpg")
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/#{filename}"), content_type)
  end
end

RSpec.configure do |config|
  config.include FileHelpers
end
