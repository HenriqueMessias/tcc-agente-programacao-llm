class Book < ApplicationRecord
  belongs_to :author
  validates :title, presence: true

  scope :search, ->(query) { where("title LIKE ?", "%#{query}%") if query.present? }
end
