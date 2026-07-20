class Category < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
