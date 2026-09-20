class Order < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :order_date, presence: true

  # Filtra pedidos por intervalo de datas. Sem filtros, retorna todos os pedidos.
  scope :in_period, ->(start_date, end_date) {
    scope = all
    scope = scope.where("order_date >= ?", start_date) if start_date.present?
    scope = scope.where("order_date <= ?", end_date) if end_date.present?
    scope
  }

  # Soma total dos valores de um escopo/relação.
  def self.total_amount(scope = all)
    scope.sum(:amount)
  end

  # Número de pedidos em um escopo/relação.
  def self.count_in(scope = all)
    scope.count
  end

  # Ticket médio (total / número de pedidos). Zero quando não há pedidos.
  def self.average_ticket(scope = all)
    count = count_in(scope)
    return 0 if count.zero?

    total_amount(scope) / count
  end

  # Hash { categoria => soma } ordenado por categoria.
  def self.totals_by_category(scope = all)
    scope.group(:category).order(:category).sum(:amount)
  end
end
