require 'rails_helper'

RSpec.describe Book, type: :model do
  let(:author) { Author.create!(name: "Machado de Assis") }

  describe "validações" do
    it "é válido com título e autor" do
      book = Book.new(title: "Dom Casmurro", published_year: 1899, author: author)
      expect(book).to be_valid
    end

    it "é inválido sem título (critério 6)" do
      book = Book.new(title: nil, author: author)
      expect(book).not_to be_valid
      expect(book.errors[:title]).to be_present
    end

    it "não persiste sem título (critério 6)" do
      expect {
        Book.create(title: nil, author: author)
      }.not_to change(Book, :count)
    end
  end

  describe "associações" do
    it "pertence a um autor (critério 5)" do
      book = Book.create!(title: "Dom Casmurro", author: author)
      expect(book.author).to eq(author)
    end
  end
end
