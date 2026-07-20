class Product < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  belongs_to :category

  enum :status, {
    available: "available",
    unavailable: "unavailable"
  }, validate: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :published, inclusion: { in: [ true, false ] }

  scope :published, -> { where(published: true) }
end
