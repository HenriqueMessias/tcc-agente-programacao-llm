# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

authors = [
  { name: "Machado de Assis" },
  { name: "Clarice Lispector" },
  { name: "Jorge Amado" }
]

authors.each do |attrs|
  Author.find_or_create_by!(name: attrs[:name])
end

books = [
  { title: "Dom Casmurro", published_year: 1899, author_name: "Machado de Assis" },
  { title: "Memórias Póstumas de Brás Cubas", published_year: 1881, author_name: "Machado de Assis" },
  { title: "A Hora da Estrela", published_year: 1977, author_name: "Clarice Lispector" },
  { title: "Capitães da Areia", published_year: 1937, author_name: "Jorge Amado" }
]

books.each do |attrs|
  author = Author.find_by(name: attrs[:author_name])
  Book.find_or_create_by!(title: attrs[:title]) do |book|
    book.published_year = attrs[:published_year]
    book.author = author
  end
end
