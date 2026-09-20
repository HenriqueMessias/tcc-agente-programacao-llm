require 'rails_helper'

RSpec.describe Order, type: :model do
  it 'is valid with amount, category and order_date' do
    order = Order.new(amount: 100.0, category: 'Eletrônicos', order_date: Date.new(2026, 1, 10))
    expect(order).to be_valid
  end

  it 'is invalid without amount' do
    order = Order.new(amount: nil, category: 'Eletrônicos', order_date: Date.new(2026, 1, 10))
    expect(order).not_to be_valid
  end

  it 'is invalid without category' do
    order = Order.new(amount: 100.0, category: nil, order_date: Date.new(2026, 1, 10))
    expect(order).not_to be_valid
  end

  it 'is invalid without order_date' do
    order = Order.new(amount: 100.0, category: 'Eletrônicos', order_date: nil)
    expect(order).not_to be_valid
  end

  describe '.in_period' do
    before do
      Order.create!(amount: 100.0, category: 'A', order_date: Date.new(2026, 1, 5))
      Order.create!(amount: 200.0, category: 'B', order_date: Date.new(2026, 2, 15))
      Order.create!(amount: 300.0, category: 'A', order_date: Date.new(2026, 3, 20))
    end

    it 'returns all orders when no bounds given' do
      expect(Order.in_period(nil, nil).count).to eq(3)
    end

    it 'filters by start_date' do
      result = Order.in_period(Date.new(2026, 2, 1), nil)
      expect(result.count).to eq(2)
    end

    it 'filters by end_date' do
      result = Order.in_period(nil, Date.new(2026, 2, 28))
      expect(result.count).to eq(2)
    end

    it 'filters by both bounds inclusively' do
      result = Order.in_period(Date.new(2026, 1, 1), Date.new(2026, 2, 28))
      expect(result.count).to eq(2)
    end
  end
end
