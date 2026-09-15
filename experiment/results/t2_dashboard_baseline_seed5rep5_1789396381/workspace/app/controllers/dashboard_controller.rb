class DashboardController < ApplicationController
  def show
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    @orders = Order.between_dates(@start_date, @end_date).ordered

    @total_sales = @orders.sum(:amount).to_d
    @orders_count = @orders.count
    @average_ticket = @orders_count.positive? ? (@total_sales / @orders_count) : 0.to_d

    @category_totals = @orders.group(:category).sum(:amount)
    @max_category_total = @category_totals.values.map { |v| v.to_d }.max || 0.to_d
  end

  private

  # Returns a Date or nil. Invalid/blank values are treated as "no filter".
  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
