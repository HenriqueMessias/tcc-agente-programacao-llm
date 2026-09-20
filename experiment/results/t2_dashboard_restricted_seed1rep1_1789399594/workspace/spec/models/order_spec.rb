require "rails_helper"

RSpec.describe Order, type: :model do
  it "é válido com amount, category e order_date" do
    order = Order.new(amount: 10.0, category: "Livros", order_date: Date.new(2026, 1, 1))
    expect(order).to be_valid
  end

  it "exige amount, category e order_date" do
    order = Order.new
    expect(order).not_to be_valid
    expect(order.errors[:amount]).to be_present
    expect(order.errors[:category]).to be_present
    expect(order.errors[:order_date]).to be_present
  end

  describe ".between_dates" do
    before do
      Order.create!(amount: 100, category: "A", order_date: Date.new(2026, 1, 10))
      Order.create!(amount: 200, category: "B", order_date: Date.new(2026, 2, 10))
    end

    it "filtra pelo intervalo inclusivo" do
      result = Order.between_dates(Date.new(2026, 1, 1), Date.new(2026, 1, 31))
      expect(result.count).to eq(1)
      expect(result.first.amount).to eq(100)
    end

    it "retorna todos quando não há filtro" do
      expect(Order.between_dates(nil, nil).count).to eq(2)
    end
  end
end
