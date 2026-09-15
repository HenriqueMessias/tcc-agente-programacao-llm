class Order < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :order_date, presence: true

  # Filtra pedidos dentro do intervalo informado.
  # Datas ausentes ou inválidas são ignoradas (não filtram por aquele limite).
  scope :in_period, ->(start_date, end_date) {
    start_on = parse_date(start_date)
    end_on   = parse_date(end_date)

    relation = all
    relation = relation.where("order_date >= ?", start_on) if start_on
    relation = relation.where("order_date <= ?", end_on) if end_on
    relation
  }

  def self.parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
