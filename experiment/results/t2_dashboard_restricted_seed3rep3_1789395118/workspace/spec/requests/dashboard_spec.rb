require 'rails_helper'

RSpec.describe 'Dashboard', type: :request do
  def create_order(amount:, category:, date:)
    Order.create!(amount: amount, category: category, order_date: date)
  end

  # Extracts a numeric value from a rendered currency string like "R$ 1.234,56".
  def parse_currency(text)
    digits = text.to_s.gsub(/[^\d,.]/, '')
    # Brazilian format: '.' thousands separator, ',' decimal separator.
    normalized = digits.gsub('.', '').gsub(',', '.')
    normalized.to_f
  end

  before do
    create_order(amount: 100.0, category: 'Eletrônicos', date: Date.new(2026, 1, 10))
    create_order(amount: 200.0, category: 'Eletrônicos', date: Date.new(2026, 1, 20))
    create_order(amount: 300.0, category: 'Vestuário', date: Date.new(2026, 2, 15))
  end

  describe 'GET /dashboard' do
    it 'returns HTTP 200 (criterion 1)' do
      get '/dashboard'
      expect(response).to have_http_status(:ok)
    end

    it 'renders the dashboard root element' do
      get '/dashboard'
      expect(response.body).to include('id="dashboard"')
    end

    it 'shows the total sales metric (criterion 2)' do
      get '/dashboard'
      expect(response.body).to match(/id="metric-total"[^>]*>.*?600/m)
    end

    it 'shows the order count metric (criterion 3)' do
      get '/dashboard'
      expect(response.body).to match(/id="metric-count"[^>]*>.*?3/m)
    end

    it 'shows the average ticket metric (criterion 4)' do
      get '/dashboard'
      # 600 / 3 = 200
      expect(response.body).to match(/id="metric-average"[^>]*>.*?200/m)
    end

    it 'renders the orders table with category and amount (criterion 5)' do
      get '/dashboard'
      expect(response.body).to include('id="orders-table"')
      expect(response.body).to include('Eletrônicos')
      expect(response.body).to include('Vestuário')
      expect(response.body).to include('100')
      expect(response.body).to include('300')
    end

    it 'renders a chart with one bar per category (criterion 6)' do
      get '/dashboard'
      expect(response.body).to include('id="chart"')
      expect(response.body.scan(/class="[^"]*chart-bar[^"]*"/).size).to eq(2)
    end

    it 'renders the filter form with start_date and end_date fields' do
      get '/dashboard'
      expect(response.body).to include('id="filter-form"')
      expect(response.body).to include('name="start_date"')
      expect(response.body).to include('name="end_date"')
    end
  end

  describe 'GET /dashboard with date filter' do
    it 'restricts metrics and table to the filtered period (criterion 7)' do
      get '/dashboard', params: { start_date: '2026-01-01', end_date: '2026-01-31' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/id="metric-total"[^>]*>.*?300/m)
      expect(response.body).to match(/id="metric-count"[^>]*>.*?2/m)
      expect(response.body).to match(/id="metric-average"[^>]*>.*?150/m)
      expect(response.body).to include('Eletrônicos')
      expect(response.body).not_to include('Vestuário')
    end

    it 'excludes orders outside the range from metrics (criterion 9)' do
      get '/dashboard', params: { start_date: '2026-02-01', end_date: '2026-02-28' }
      expect(response.body).to match(/id="metric-total"[^>]*>.*?300/m)
      expect(response.body).to match(/id="metric-count"[^>]*>.*?1/m)
      expect(response.body).to include('Vestuário')
      expect(response.body).not_to include('Eletrônicos')
    end

    it 'shows empty state for a period with no orders, without HTTP 500 (criterion 8)' do
      get '/dashboard', params: { start_date: '2020-01-01', end_date: '2020-01-31' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="empty-state"')
    end

    it 'does not raise on invalid date params' do
      get '/dashboard', params: { start_date: 'not-a-date', end_date: 'also-bad' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'consistency between table and total (criterion 10)' do
    it 'table amounts sum to the total metric for the filtered period' do
      get '/dashboard', params: { start_date: '2026-01-01', end_date: '2026-01-31' }
      body = response.body
      total_text = body[/id="metric-total"[^>]*>(.*?)<\/div>/m, 1]
      total = parse_currency(total_text)
      amounts = body.scan(/data-amount="([\d.]+)"/).flatten.map(&:to_f)
      expect(amounts.sum).to eq(total)
    end
  end
end
