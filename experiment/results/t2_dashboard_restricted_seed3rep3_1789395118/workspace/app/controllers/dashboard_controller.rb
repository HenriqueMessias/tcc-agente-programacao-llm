class DashboardController < ApplicationController
  def index
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    @orders = Order.in_period(@start_date, @end_date).order(order_date: :desc)

    @total = @orders.sum(:amount)
    @count = @orders.count
    @average = @count.zero? ? 0 : (@total / @count)

    @by_category = @orders.by_category
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
