require 'rails_helper'

RSpec.describe Author, type: :model do
  describe "validações" do
    it "é válido com um nome" do
      author = Author.new(name: "Machado de Assis")
      expect(author).to be_valid
    end

    it "é inválido sem nome (critério 4)" do
      author = Author.new(name: nil)
      expect(author).not_to be_valid
      expect(author.errors[:name]).to be_present
    end

    it "não persiste sem nome (critério 4)" do
      expect { Author.create(name: nil) }.not_to change(Author, :count)
    end
  end

  describe "associações" do
    it "possui muitos livros" do
      author = Author.create!(name: "Autor")
      author.books.create!(title: "Livro")
      expect(author.books.count).to eq(1)
    end

    it "remove os livros associados ao ser excluído (critério 11)" do
      author = Author.create!(name: "Autor")
      author.books.create!(title: "Livro A")
      author.books.create!(title: "Livro B")

      expect { author.destroy }.to change(Book, :count).by(-2)
    end
  end
end
