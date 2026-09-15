class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true
  validates :author, presence: true

  scope :search, ->(query) {
    if query.present?
      where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
    else
      all
    end
  }
end
