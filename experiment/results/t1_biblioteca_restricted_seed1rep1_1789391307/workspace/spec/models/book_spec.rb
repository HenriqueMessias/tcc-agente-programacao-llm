require "rails_helper"

RSpec.describe Book, type: :model do
  let(:author) { Author.create!(name: "Autor Base") }

  it "é válido com título e autor" do
    expect(Book.new(title: "Dom Casmurro", author: author)).to be_valid
  end

  it "é inválido sem título (critério 6)" do
    book = Book.new(title: nil, author: author)
    expect(book).not_to be_valid
    expect(book.errors[:title]).to be_present
  end

  it "pertence a um autor" do
    expect(Book.reflect_on_association(:author).macro).to eq(:belongs_to)
  end

  describe ".search (critério 10)" do
    before do
      Book.create!(title: "Dom Casmurro", author: author)
      Book.create!(title: "Memórias Póstumas", author: author)
      Book.create!(title: "O Cortiço", author: author)
    end

    it "retorna todos quando query está em branco" do
      expect(Book.search(nil).count).to eq(3)
      expect(Book.search("").count).to eq(3)
    end

    it "faz busca parcial pelo título" do
      results = Book.search("Casmurro")
      expect(results.map(&:title)).to eq(["Dom Casmurro"])
    end

    it "faz busca case-insensitive" do
      results = Book.search("casmurro")
      expect(results.map(&:title)).to eq(["Dom Casmurro"])
    end

    it "retorna apenas os livros correspondentes" do
      results = Book.search("memórias")
      expect(results.map(&:title)).to eq(["Memórias Póstumas"])
    end
  end
end
