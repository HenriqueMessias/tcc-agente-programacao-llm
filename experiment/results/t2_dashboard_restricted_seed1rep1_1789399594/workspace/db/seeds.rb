Order.destroy_all

categories = ["Eletrônicos", "Livros", "Roupas", "Alimentos", "Brinquedos"]

40.times do |i|
  Order.create!(
    amount: rand(50.0..1500.0).round(2),
    category: categories.sample,
    order_date: Date.new(2026, 1, 1) + rand(0..120)
  )
end

puts "Criados #{Order.count} pedidos."
