class ProductImage < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_IMAGE_SIZE = 10.megabytes

  belongs_to :product
  has_one_attached :image

  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :acceptable_image

  private

  def acceptable_image
    unless image.attached?
      errors.add(:image, "must be attached")
      return
    end

    unless ALLOWED_CONTENT_TYPES.include?(image.blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, or WebP file")
    end

    if image.blob.byte_size > MAX_IMAGE_SIZE
      errors.add(:image, "must be 10 MB or smaller")
    end
  end
end
