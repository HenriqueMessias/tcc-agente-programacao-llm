Order.delete_all

orders = [
  { amount: 1500.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 5) },
  { amount: 250.50,  category: "Livros",      order_date: Date.new(2026, 1, 10) },
  { amount: 3200.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 15) },
  { amount: 89.90,   category: "Livros",      order_date: Date.new(2026, 1, 20) },
  { amount: 780.00,  category: "Roupas",      order_date: Date.new(2026, 1, 25) },
  { amount: 430.00,  category: "Roupas",      order_date: Date.new(2026, 2, 3) },
  { amount: 120.00,  category: "Livros",      order_date: Date.new(2026, 2, 12) },
  { amount: 2100.00, category: "Eletrônicos", order_date: Date.new(2026, 2, 18) }
]

orders.each { |attrs| Order.create!(attrs) }

puts "Seeded #{Order.count} orders."
