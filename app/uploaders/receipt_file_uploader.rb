# frozen_string_literal: true

class ReceiptFileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    user_slug = model.user.name.parameterize
    month = (model.spent_on || model.created_at&.to_date || Date.current).strftime("%Y-%m")
    "storage/receipts/#{user_slug}/#{month}"
  end

  def filename
    "#{Time.current.strftime("%Y%m%d_%H%M%S")}_#{original_filename}"
  end

  def extension_allowlist
    %w[jpg jpeg png heic webp pdf]
  end

  def size_range
    1..(10.megabytes)
  end
end
