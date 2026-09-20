Order.delete_all

orders = [
  { amount: 1200.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 5) },
  { amount: 350.50,  category: "Livros",      order_date: Date.new(2026, 1, 12) },
  { amount: 89.90,   category: "Roupas",      order_date: Date.new(2026, 1, 18) },
  { amount: 2400.00, category: "Eletrônicos", order_date: Date.new(2026, 1, 25) },
  { amount: 150.00,  category: "Livros",      order_date: Date.new(2026, 2, 3) },
  { amount: 320.75,  category: "Roupas",      order_date: Date.new(2026, 2, 14) },
  { amount: 780.00,  category: "Eletrônicos", order_date: Date.new(2026, 2, 22) }
]

orders.each { |attrs| Order.create!(attrs) }

puts "Criados #{Order.count} pedidos."
