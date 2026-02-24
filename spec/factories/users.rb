# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    sequence(:google_uid) { |n| "google_uid_#{n}" }
    avatar_url { "https://example.com/avatar.jpg" }
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end
