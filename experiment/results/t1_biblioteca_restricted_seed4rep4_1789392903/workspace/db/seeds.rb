# Dados de exemplo para a biblioteca.
# Idempotente: pode ser executado múltiplas vezes.

authors = [
  "Machado de Assis",
  "Jorge Amado",
  "Clarice Lispector"
]

authors.each do |name|
  Author.find_or_create_by!(name: name)
end

books = [
  { title: "Dom Casmurro", published_year: 1899, author: "Machado de Assis" },
  { title: "Memórias Póstumas de Brás Cubas", published_year: 1881, author: "Machado de Assis" },
  { title: "Capitães da Areia", published_year: 1937, author: "Jorge Amado" },
  { title: "A Hora da Estrela", published_year: 1977, author: "Clarice Lispector" }
]

books.each do |attrs|
  author = Author.find_by(name: attrs[:author])
  Book.find_or_create_by!(title: attrs[:title]) do |book|
    book.published_year = attrs[:published_year]
    book.author = author
  end
end
