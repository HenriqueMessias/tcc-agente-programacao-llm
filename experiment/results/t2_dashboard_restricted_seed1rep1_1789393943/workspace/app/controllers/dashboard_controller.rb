class DashboardController < ApplicationController
  def index
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    @orders = Order.in_period(@start_date, @end_date).order(order_date: :desc, id: :desc)

    @total = Order.total_amount(@orders)
    @count = Order.count_in(@orders)
    @average = Order.average_ticket(@orders)

    @totals_by_category = Order.totals_by_category(@orders)
    @max_category_total = @totals_by_category.values.max || 0
    @empty = @count.zero?
  end

  private

  # Faz parse seguro de uma data no formato YYYY-MM-DD.
  # Retorna nil para valores em branco ou inválidos (sem levantar erro).
  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
