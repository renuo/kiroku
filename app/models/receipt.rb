# frozen_string_literal: true

class Receipt < ApplicationRecord
  belongs_to :user
  mount_uploader :file, ReceiptFileUploader

  validates :file, presence: true, on: :create

  scope :recorded, -> { where.not(recorded_on: nil) }
  scope :unrecorded, -> { where(recorded_on: nil) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :ordered, -> { order(Arel.sql("COALESCE(spent_on, DATE(created_at)) DESC")) }

  def effective_date
    spent_on || created_at.to_date
  end

  def recorded?
    recorded_on.present?
  end

  def image_file?
    file.file&.extension&.match?(/\A(jpg|jpeg|png|heic|webp)\z/i)
  end

  def pdf_file?
    file.file&.extension&.match?(/\Apdf\z/i)
  end

  def grouped_by_month(receipts)
    receipts.group_by { |r| r.effective_date.beginning_of_month }
  end
end
