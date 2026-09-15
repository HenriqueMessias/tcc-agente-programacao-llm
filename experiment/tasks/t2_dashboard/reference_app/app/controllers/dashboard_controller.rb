class DashboardController < ApplicationController
  def show
    @start_date = params[:start_date].presence
    @end_date = params[:end_date].presence
    @orders = Order.between_dates(@start_date, @end_date).order(:order_date)

    @total = @orders.sum(:amount)
    @count = @orders.count
    @average = @count.zero? ? 0 : (@total / @count)
    @by_category = @orders.group(:category).sum(:amount)
  end
end
