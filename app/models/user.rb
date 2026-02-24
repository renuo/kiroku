# frozen_string_literal: true

class User < ApplicationRecord
  has_many :receipts, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :google_uid, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    find_or_create_by(google_uid: auth.uid) do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.avatar_url = auth.info.image
    end
  end
end
