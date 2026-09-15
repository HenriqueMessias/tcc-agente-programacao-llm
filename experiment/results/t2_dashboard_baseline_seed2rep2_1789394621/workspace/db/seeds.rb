Order.delete_all

orders = [
  { amount: 1500.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 5) },
  { amount: 250.50,  category: "Livros",      order_date: Date.new(2026, 1, 12) },
  { amount: 3200.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 20) },
  { amount: 89.90,   category: "Acessórios",  order_date: Date.new(2026, 1, 28) },
  { amount: 640.00,  category: "Livros",      order_date: Date.new(2026, 2, 3) },
  { amount: 1200.00, category: "Móveis",      order_date: Date.new(2026, 2, 14) },
  { amount: 75.00,   category: "Acessórios",  order_date: Date.new(2026, 2, 22) },
  { amount: 980.00,  category: "Móveis",      order_date: Date.new(2026, 3, 1) }
]

orders.each { |attrs| Order.create!(attrs) }

puts "Seeded #{Order.count} orders."
