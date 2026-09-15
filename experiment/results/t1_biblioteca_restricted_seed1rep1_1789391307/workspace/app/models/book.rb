class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true

  scope :search, ->(query) {
    if query.present?
      where("LOWER(title) LIKE ?", "%#{query.downcase}%")
    else
      all
    end
  }
end
