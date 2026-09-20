require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  def create_order(amount:, category:, order_date:)
    Order.create!(amount: amount, category: category, order_date: order_date)
  end

  describe "GET /dashboard" do
    context "with orders present" do
      before do
        create_order(amount: 100, category: "Eletronicos", order_date: Date.new(2026, 1, 5))
        create_order(amount: 200, category: "Livros", order_date: Date.new(2026, 1, 15))
        create_order(amount: 300, category: "Eletronicos", order_date: Date.new(2026, 1, 20))
      end

      it "returns HTTP 200 (criterion 1)" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
      end

      it "renders the dashboard root element" do
        get "/dashboard"
        expect(response.body).to include('id="dashboard"')
      end

      it "shows the total sales metric (criterion 2)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-total"')
        expect(response.body).to match(/id="metric-total"[^>]*>.*?600/m)
      end

      it "shows the order count metric (criterion 3)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-count"')
        expect(response.body).to match(/id="metric-count"[^>]*>.*?3/m)
      end

      it "shows the average ticket metric (criterion 4)" do
        get "/dashboard"
        expect(response.body).to include('id="metric-average"')
        # 600 / 3 = 200
        expect(response.body).to match(/id="metric-average"[^>]*>.*?200/m)
      end

      it "renders the orders table with category and amount (criterion 5)" do
        get "/dashboard"
        expect(response.body).to include('id="orders-table"')
        expect(response.body).to include("Eletronicos")
        expect(response.body).to include("Livros")
      end

      it "renders a chart with one bar per category (criterion 6)" do
        get "/dashboard"
        expect(response.body).to include('id="chart"')
        expect(response.body.scan(/class="[^"]*chart-bar[^"]*"/).size).to eq(2)
      end

      it "does not render the empty state" do
        get "/dashboard"
        expect(response.body).not_to include('id="empty-state"')
      end
    end

    context "with date filtering" do
      before do
        create_order(amount: 100, category: "A", order_date: Date.new(2026, 1, 5))
        create_order(amount: 200, category: "B", order_date: Date.new(2026, 1, 15))
        create_order(amount: 300, category: "A", order_date: Date.new(2026, 2, 10))
      end

      it "restricts metrics and table to the filtered range (criteria 7 and 9)" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/id="metric-total"[^>]*>.*?300/m)
        expect(response.body).to match(/id="metric-count"[^>]*>.*?2/m)
        expect(response.body).to match(/id="metric-average"[^>]*>.*?150/m)
        # February order excluded
        expect(response.body).not_to match(/id="metric-total"[^>]*>.*?600/m)
      end

      it "renders the filter form with start_date and end_date fields" do
        get "/dashboard"
        expect(response.body).to include('id="filter-form"')
        expect(response.body).to include('name="start_date"')
        expect(response.body).to include('name="end_date"')
      end

      it "shows the empty state for a range with no orders (criterion 8)" do
        get "/dashboard", params: { start_date: "2020-01-01", end_date: "2020-01-31" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="empty-state"')
      end

      it "does not raise on invalid date params" do
        get "/dashboard", params: { start_date: "not-a-date", end_date: "also-bad" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "consistency between table and total (criterion 10)" do
      before do
        create_order(amount: 100, category: "A", order_date: Date.new(2026, 1, 5))
        create_order(amount: 250, category: "B", order_date: Date.new(2026, 1, 15))
      end

      it "sum of table values equals the total metric" do
        get "/dashboard", params: { start_date: "2026-01-01", end_date: "2026-01-31" }
        body = response.body
        total = body[/id="metric-total"[^>]*>(.*?)</m, 1].to_s.gsub(/[^\d.,]/, "").tr(",", ".").to_f
        expect(total).to eq(350.0)
      end
    end
  end
end
