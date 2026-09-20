# frozen_string_literal: true

# Dados de exemplo para a aplicação de biblioteca.
# Idempotente: pode ser executado várias vezes sem duplicar registros.

authors = {
  "Machado de Assis" => [
    ["Dom Casmurro", 1899],
    ["Mem\u00F3rias P\u00F3stumas de Br\u00E1s Cubas", 1881]
  ],
  "Jorge Amado" => [
    ["Capit\u00E3es da Areia", 1937],
    ["Gabriela, Cravo e Canela", 1958]
  ],
  "Clarice Lispector" => [
    ["A Hora da Estrela", 1977],
    ["Perto do Cora\u00E7\u00E3o Selvagem", 1943]
  ]
}

authors.each do |author_name, books|
  author = Author.find_or_create_by!(name: author_name)

  books.each do |title, year|
    Book.find_or_create_by!(title: title, author: author) do |book|
      book.published_year = year
    end
  end
end
