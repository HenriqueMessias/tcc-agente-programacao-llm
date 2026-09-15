class DashboardController < ApplicationController
  def show
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    @orders = Order.between_dates(@start_date, @end_date).order(order_date: :desc, id: :desc)

    @total_sales = @orders.sum(:amount).to_d
    @orders_count = @orders.count
    @average_ticket = @orders_count.positive? ? (@total_sales / @orders_count) : 0.to_d

    @totals_by_category = @orders.group(:category).sum(:amount)
    @max_category_total = @totals_by_category.values.map(&:to_d).max || 0.to_d
  end

  private

  # Parses a "YYYY-MM-DD" string into a Date, returning nil for blank/invalid input.
  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
