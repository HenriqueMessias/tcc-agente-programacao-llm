# Query object that aggregates order metrics for a given date range.
#
# Encapsulates the filtering and aggregation logic so the controller stays
# thin and the calculations can be reused/tested in isolation.
class DashboardMetrics
  attr_reader :start_date, :end_date

  def initialize(start_date: nil, end_date: nil)
    @start_date = start_date
    @end_date = end_date
  end

  def orders
    @orders ||= Order.between_dates(start_date, end_date).ordered
  end

  def total_sales
    @total_sales ||= orders.sum(:amount)
  end

  def orders_count
    @orders_count ||= orders.count
  end

  def average_ticket
    return 0 if orders_count.zero?

    total_sales / orders_count
  end

  def by_category
    @by_category ||= orders.group(:category).sum(:amount)
  end

  def empty?
    orders_count.zero?
  end
end
