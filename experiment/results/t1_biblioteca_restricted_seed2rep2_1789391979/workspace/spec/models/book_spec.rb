require 'rails_helper'

RSpec.describe Book, type: :model do
  let(:author) { Author.create!(name: "Machado de Assis") }

  it "is valid with a title and author" do
    expect(Book.new(title: "Dom Casmurro", author: author)).to be_valid
  end

  it "is invalid without a title" do
    book = Book.new(title: nil, author: author)
    expect(book).not_to be_valid
    expect(book.errors[:title]).to be_present
  end

  it "belongs to an author" do
    book = Book.create!(title: "Dom Casmurro", author: author)
    expect(book.author).to eq(author)
  end

  describe ".search" do
    before do
      Book.create!(title: "Dom Casmurro", author: author)
      Book.create!(title: "Memórias Póstumas", author: author)
    end

    it "returns books matching a partial title (case-insensitive)" do
      results = Book.search("casmurro")
      expect(results.map(&:title)).to eq(["Dom Casmurro"])
    end

    it "matches partial substrings" do
      results = Book.search("mem")
      expect(results.map(&:title)).to eq(["Memórias Póstumas"])
    end

    it "returns all books when query is blank" do
      expect(Book.search(nil).count).to eq(2)
      expect(Book.search("").count).to eq(2)
    end
  end
end
