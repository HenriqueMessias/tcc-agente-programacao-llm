class Order < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :order_date, presence: true

  scope :in_period, ->(start_date, end_date) {
    relation = all
    relation = relation.where("order_date >= ?", start_date) if start_date.present?
    relation = relation.where("order_date <= ?", end_date) if end_date.present?
    relation
  }

  scope :ordered, -> { order(order_date: :asc, id: :asc) }

  # Soma dos valores do escopo informado (BigDecimal; 0 quando vazio).
  def self.total_sales(scope = all)
    scope.sum(:amount) || BigDecimal("0")
  end

  # Número de pedidos do escopo informado.
  def self.count_for(scope = all)
    scope.count
  end

  # Ticket médio = total / número de pedidos (0 quando não há pedidos).
  def self.average_ticket(scope = all)
    count = count_for(scope)
    return BigDecimal("0") if count.zero?

    total_sales(scope) / count
  end

  # Hash { categoria => soma } ordenado por valor desc (para o gráfico).
  def self.totals_by_category(scope = all)
    scope.group(:category).sum(:amount).sort_by { |_category, total| -total.to_f }.to_h
  end
end
