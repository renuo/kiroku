# frozen_string_literal: true

class User < ApplicationRecord
  has_many :receipts, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :google_uid, uniqueness: true, allow_nil: true
  validates :slack_uid, uniqueness: true, allow_nil: true

  def self.from_omniauth(auth)
    find_or_create_by(google_uid: auth.uid) do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.avatar_url = auth.info.image
    end
  end

  def self.find_or_create_from_slack(slack_uid:, email:, name:)
    user = find_by(email: email)
    if user
      user.update!(slack_uid: slack_uid)
      return user
    end

    create!(slack_uid: slack_uid, email: email, name: name)
  end
end
