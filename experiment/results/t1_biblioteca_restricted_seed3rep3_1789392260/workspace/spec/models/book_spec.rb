require 'rails_helper'

RSpec.describe Book, type: :model do
  let!(:author) { Author.create!(name: "Autor Base") }

  # Critério 6: validação de presença de título
  it "é inválido sem título" do
    book = Book.new(title: "", author: author)
    expect(book).not_to be_valid
    expect(book.errors[:title]).to be_present
  end

  it "é válido com título e autor" do
    expect(Book.new(title: "Livro Válido", author: author)).to be_valid
  end

  # Critério 5: pertence a um autor
  it "pertence a um autor" do
    book = Book.create!(title: "Livro", author: author)
    expect(book.author).to eq(author)
  end

  # Critério 10: busca parcial case-insensitive
  describe ".search_by_title" do
    it "encontra por parte do título ignorando maiúsculas/minúsculas" do
      match = Book.create!(title: "O Hobbit", author: author)
      Book.create!(title: "Dom Casmurro", author: author)

      results = Book.search_by_title("hobbit")
      expect(results).to include(match)
      expect(results.count).to eq(1)
    end
  end
end
