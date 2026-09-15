Order.destroy_all

categories = ["Eletrônicos", "Roupas", "Alimentos", "Livros", "Brinquedos"]

60.times do |i|
  Order.create!(
    amount: rand(50.0..1500.0).round(2),
    category: categories.sample,
    order_date: Date.today - rand(0..120)
  )
end

puts "Criados #{Order.count} pedidos."
