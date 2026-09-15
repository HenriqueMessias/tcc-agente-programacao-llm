class Order < ApplicationRecord
  validates :amount, presence: true, numericality: true
  validates :category, presence: true
  validates :order_date, presence: true

  scope :between_dates, ->(start_date, end_date) {
    scope = all
    scope = scope.where("order_date >= ?", start_date) if start_date.present?
    scope = scope.where("order_date <= ?", end_date) if end_date.present?
    scope
  }
end
