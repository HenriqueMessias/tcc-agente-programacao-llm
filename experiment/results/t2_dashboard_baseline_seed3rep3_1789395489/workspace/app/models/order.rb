class Order < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :order_date, presence: true

  scope :between_dates, ->(start_date, end_date) {
    relation = all
    relation = relation.where("order_date >= ?", start_date) if start_date
    relation = relation.where("order_date <= ?", end_date) if end_date
    relation
  }

  scope :by_category, -> { group(:category).order(Arel.sql("SUM(amount) DESC")) }
end
