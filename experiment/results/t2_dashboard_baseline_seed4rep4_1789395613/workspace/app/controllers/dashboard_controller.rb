class DashboardController < ApplicationController
  def show
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    @orders = Order.between_dates(@start_date, @end_date).ordered

    @total = @orders.sum(:amount).to_d
    @count = @orders.count
    @average = @count.positive? ? (@total / @count) : 0.to_d

    @by_category = @orders.group(:category).sum(:amount)
    @max_category_total = @by_category.values.map { |v| v.to_d }.max || 0.to_d
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
