class DashboardController < ApplicationController
  def show
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    scope = Order.in_period(@start_date, @end_date)

    @orders = scope.ordered.to_a
    @orders_count = Order.count_for(scope)
    @total_sales = Order.total_sales(scope)
    @average_ticket = Order.average_ticket(scope)
    @totals_by_category = Order.totals_by_category(scope)
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
