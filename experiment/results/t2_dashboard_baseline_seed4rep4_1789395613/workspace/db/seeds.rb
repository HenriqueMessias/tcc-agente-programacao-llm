Order.delete_all

orders = [
  { amount: 150.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 5) },
  { amount: 89.90,  category: "Livros",      order_date: Date.new(2026, 1, 12) },
  { amount: 320.50, category: "Eletrônicos", order_date: Date.new(2026, 1, 20) },
  { amount: 45.00,  category: "Roupas",      order_date: Date.new(2026, 1, 25) },
  { amount: 210.00, category: "Livros",      order_date: Date.new(2026, 2, 3) },
  { amount: 99.99,  category: "Roupas",      order_date: Date.new(2026, 2, 14) },
  { amount: 500.00, category: "Eletrônicos", order_date: Date.new(2026, 2, 28) }
]

orders.each { |attrs| Order.create!(attrs) }

puts "Seeded #{Order.count} orders."
