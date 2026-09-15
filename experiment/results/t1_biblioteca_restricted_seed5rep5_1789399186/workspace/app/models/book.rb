class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true

  scope :search_by_title, ->(query) {
    where("title LIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
  }
end
