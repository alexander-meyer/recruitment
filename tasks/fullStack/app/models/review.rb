class Review < ApplicationRecord
  belongs_to :product

  validates :product_id, presence: true
  validates :reviewer_name, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 1000 }
  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
end
