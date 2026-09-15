class DashboardController < ApplicationController
  def index
    @start_date = Order.parse_date(params[:start_date])
    @end_date   = Order.parse_date(params[:end_date])

    @orders = Order.in_period(@start_date, @end_date).order(order_date: :desc)

    @total   = @orders.sum(:amount)
    @count   = @orders.count
    @average = @count.positive? ? (@total / @count) : 0

    @by_category = @orders.group(:category).sum(:amount)
  end
end
