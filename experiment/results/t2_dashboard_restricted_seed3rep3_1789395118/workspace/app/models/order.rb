class Order < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :order_date, presence: true

  scope :in_period, ->(start_date, end_date) {
    relation = all
    relation = relation.where(order_date: start_date..) if start_date.present?
    relation = relation.where(order_date: ..end_date) if end_date.present?
    relation
  }

  scope :by_category, -> { group(:category).sum(:amount) }
end
