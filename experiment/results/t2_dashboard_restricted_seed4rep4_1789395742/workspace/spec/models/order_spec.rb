require "rails_helper"

RSpec.describe Order, type: :model do
  def create_order(amount:, category:, order_date:)
    Order.create!(amount: amount, category: category, order_date: order_date)
  end

  describe "validations" do
    it "is valid with amount, category and order_date" do
      expect(create_order(amount: 10, category: "A", order_date: Date.new(2026, 1, 1))).to be_persisted
    end

    it "is invalid without amount" do
      order = Order.new(amount: nil, category: "A", order_date: Date.new(2026, 1, 1))
      expect(order).not_to be_valid
    end

    it "is invalid without category" do
      order = Order.new(amount: 10, category: nil, order_date: Date.new(2026, 1, 1))
      expect(order).not_to be_valid
    end

    it "is invalid without order_date" do
      order = Order.new(amount: 10, category: "A", order_date: nil)
      expect(order).not_to be_valid
    end
  end

  describe ".between_dates" do
    before do
      create_order(amount: 100, category: "A", order_date: Date.new(2026, 1, 5))
      create_order(amount: 200, category: "B", order_date: Date.new(2026, 1, 15))
      create_order(amount: 300, category: "A", order_date: Date.new(2026, 2, 10))
    end

    it "returns all orders when no dates given" do
      expect(Order.between_dates(nil, nil).count).to eq(3)
    end

    it "filters by inclusive range" do
      result = Order.between_dates(Date.new(2026, 1, 1), Date.new(2026, 1, 31))
      expect(result.count).to eq(2)
      expect(result.sum(:amount)).to eq(300)
    end

    it "filters by start_date only" do
      result = Order.between_dates(Date.new(2026, 1, 10), nil)
      expect(result.count).to eq(2)
    end

    it "filters by end_date only" do
      result = Order.between_dates(nil, Date.new(2026, 1, 31))
      expect(result.count).to eq(2)
    end
  end

  describe "aggregations" do
    before do
      create_order(amount: 100, category: "A", order_date: Date.new(2026, 1, 5))
      create_order(amount: 200, category: "B", order_date: Date.new(2026, 1, 15))
      create_order(amount: 300, category: "A", order_date: Date.new(2026, 2, 10))
    end

    it "sums amounts" do
      expect(Order.sum(:amount)).to eq(600)
    end

    it "groups totals by category" do
      expect(Order.group(:category).sum(:amount)).to eq("A" => 400, "B" => 200)
    end
  end
end
