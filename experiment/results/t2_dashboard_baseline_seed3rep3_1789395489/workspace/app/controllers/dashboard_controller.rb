class DashboardController < ApplicationController
  def show
    @start_date = parse_date(params[:start_date])
    @end_date   = parse_date(params[:end_date])

    @orders = Order.between_dates(@start_date, @end_date).order(order_date: :desc, id: :desc)

    @total_sales = @orders.sum(:amount).to_d
    @orders_count = @orders.count
    @average_ticket = @orders_count.positive? ? (@total_sales / @orders_count) : 0.to_d

    @category_totals = @orders.group(:category).sum(:amount).sort_by { |_cat, total| -total.to_d }
    @max_category_total = @category_totals.map { |_cat, total| total.to_d }.max || 0.to_d
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
