require 'rails_helper'

RSpec.describe Author, type: :model do
  # Critério 4: validação de presença de nome
  it "é inválido sem nome" do
    author = Author.new(name: "")
    expect(author).not_to be_valid
    expect(author.errors[:name]).to be_present
  end

  it "é válido com nome" do
    expect(Author.new(name: "Autor Válido")).to be_valid
  end

  # Critério 11: associação respeitada
  it "remove os livros associados ao ser destruído" do
    author = Author.create!(name: "Autor com Livros")
    Book.create!(title: "Livro 1", author: author)
    Book.create!(title: "Livro 2", author: author)

    expect { author.destroy }.to change(Book, :count).by(-2)
  end
end
