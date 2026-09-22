class Product < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  belongs_to :category
  has_many :product_images,
           -> { order(position: :asc, id: :asc) },
           dependent: :destroy

  enum :status, {
    available: "available",
    made_to_order: "made_to_order",
    unavailable: "unavailable"
  }, validate: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :published, inclusion: { in: [ true, false ] }

  scope :published, -> { where(published: true) }
  scope :publicly_visible, lambda {
    published.joins(:category).merge(Category.active)
  }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def primary_image
    product_images.first
  end
end
