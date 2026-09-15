class DashboardController < ApplicationController
  def index
    @start_date = parse_date(params[:start_date])
    @end_date = parse_date(params[:end_date])

    @metrics = DashboardMetrics.new(start_date: @start_date, end_date: @end_date)

    @orders = @metrics.orders
    @total_sales = @metrics.total_sales
    @orders_count = @metrics.orders_count
    @average_ticket = @metrics.average_ticket
    @by_category = @metrics.by_category
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
