# frozen_string_literal: true

class ReceiptFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

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

  version :preview do
    process :convert_pdf_to_png, if: :pdf?
    process resize_to_limit: [2400, 2400]

    def full_filename(for_file)
      super.sub(/\.\w+\z/, ".png")
    end
  end

  private

  def convert_pdf_to_png
    minimagick! do |builder|
      builder
        .loader(density: 400, page: 0)
        .flatten
        .convert("png")
    end
  end

  def pdf?(new_file)
    new_file.content_type == "application/pdf" || new_file.path&.end_with?(".pdf")
  end
end
