module DashboardHelper
  def format_currency(value)
    number_to_currency(value, unit: "R$ ", separator: ",", delimiter: ".", precision: 2)
  end

  # Returns the bar height (as a percentage of the largest value) for a chart
  # bar, so the view stays declarative.
  def chart_bar_height(value, max_value)
    max = max_value.to_f
    return 0 unless max.positive?

    (value.to_f / max * 100).round(2)
  end
end
