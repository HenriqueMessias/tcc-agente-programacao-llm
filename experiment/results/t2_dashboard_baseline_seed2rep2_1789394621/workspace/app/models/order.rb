class Order < ApplicationRecord
  validates :amount, presence: true, numericality: true
  validates :category, presence: true
  validates :order_date, presence: true

  # Orders whose order_date falls within the given range.
  # A nil bound means "unbounded" on that side.
  scope :in_period, ->(start_date, end_date) {
    relation = all
    relation = relation.where("order_date >= ?", start_date) if start_date.present?
    relation = relation.where("order_date <= ?", end_date) if end_date.present?
    relation
  }

  # Aggregated total amount grouped by category, ordered by total desc.
  def self.totals_by_category
    group(:category).order(Arel.sql("SUM(amount) DESC")).sum(:amount)
  end
end
