class Book < ApplicationRecord
  belongs_to :author

  validates :title, presence: true

  scope :search_by_title, ->(query) {
    if query.present?
      where("LOWER(title) LIKE ?", "%#{sanitize_sql_like(query.downcase)}%")
    else
      all
    end
  }
end
