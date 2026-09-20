class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true
  validates :published_year, numericality: { only_integer: true, allow_nil: true }

  scope :search_by_title, ->(query) {
    if query.present?
      where("LOWER(title) LIKE ?", "%#{query.downcase}%")
    else
      all
    end
  }
end
