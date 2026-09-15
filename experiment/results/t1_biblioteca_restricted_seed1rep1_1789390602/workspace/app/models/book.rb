class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true
  validates :published_year, numericality: { only_integer: true, allow_nil: true }

  scope :search_by_title, ->(query) {
    where("LOWER(title) LIKE ?", "%#{query.to_s.downcase}%")
  }
end
