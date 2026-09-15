class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true

  scope :search_by_title, ->(query) {
    if query.present?
      where("LOWER(title) LIKE ?", "%#{query.downcase}%")
    else
      all
    end
  }
end
