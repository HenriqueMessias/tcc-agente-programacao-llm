# Sample orders for the sales dashboard.
Order.delete_all

orders = [
  { amount: 1200.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 5) },
  { amount: 350.50,  category: "Eletrônicos", order_date: Date.new(2026, 1, 12) },
  { amount: 89.90,   category: "Livros",      order_date: Date.new(2026, 1, 18) },
  { amount: 45.00,   category: "Livros",      order_date: Date.new(2026, 1, 22) },
  { amount: 780.00,  category: "Móveis",      order_date: Date.new(2026, 1, 28) },
  { amount: 2100.00, category: "Móveis",      order_date: Date.new(2026, 2, 3) },
  { amount: 150.75,  category: "Vestuário",   order_date: Date.new(2026, 2, 10) },
  { amount: 320.00,  category: "Vestuário",   order_date: Date.new(2026, 2, 15) },
  { amount: 640.25,  category: "Eletrônicos", order_date: Date.new(2026, 2, 20) },
  { amount: 99.99,   category: "Livros",      order_date: Date.new(2026, 3, 1) }
]

orders.each { |attrs| Order.create!(attrs) }

puts "Created #{Order.count} orders."
