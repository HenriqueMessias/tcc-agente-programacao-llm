class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true
  validates :published_year, numericality: { only_integer: true, allow_nil: true }

  scope :search, ->(query) {
    if query.present?
      where("LOWER(title) LIKE ?", "%#{query.to_s.downcase}%")
    else
      all
    end
  }
end
