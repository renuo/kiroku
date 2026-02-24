# frozen_string_literal: true

FactoryBot.define do
  factory :receipt do
    user
    spent_on { Date.new(2026, 1, 15) }
    file { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test_receipt.jpg"), "image/jpeg") }

    trait :recorded do
      code { "BK-001" }
      recorded_on { Time.zone.parse("2026-01-20 10:00:00") }
    end

    trait :admin_owned do
      user factory: %i[user admin]
    end
  end
end
