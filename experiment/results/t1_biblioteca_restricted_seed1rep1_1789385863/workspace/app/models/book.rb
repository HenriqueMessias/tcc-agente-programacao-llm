class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true

  scope :search_by_title, ->(query) {
    if query.present?
      where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
    else
      all
    end
  }
end
