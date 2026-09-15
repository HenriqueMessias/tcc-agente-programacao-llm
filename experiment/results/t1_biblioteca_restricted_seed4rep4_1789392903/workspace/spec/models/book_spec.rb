require 'rails_helper'

RSpec.describe Book, type: :model do
  let(:author) { Author.create!(name: 'Machado de Assis') }

  describe 'validations' do
    it 'is valid with a title and author' do
      book = Book.new(title: 'Dom Casmurro', author: author)
      expect(book).to be_valid
    end

    it 'is invalid without a title' do
      book = Book.new(title: nil, author: author)
      expect(book).not_to be_valid
      expect(book.errors[:title]).to be_present
    end

    it 'is invalid without an author' do
      book = Book.new(title: 'Dom Casmurro', author: nil)
      expect(book).not_to be_valid
    end
  end

  describe '.search' do
    before do
      Book.create!(title: 'Dom Casmurro', author: author)
      Book.create!(title: 'Memórias Póstumas', author: author)
      Book.create!(title: 'O Cortiço', author: author)
    end

    it 'returns books matching a partial title (case-insensitive)' do
      results = Book.search('casmurro')
      expect(results.map(&:title)).to eq(['Dom Casmurro'])
    end

    it 'is case-insensitive' do
      results = Book.search('DOM')
      expect(results.map(&:title)).to eq(['Dom Casmurro'])
    end

    it 'returns all books when query is blank' do
      expect(Book.search(nil).count).to eq(3)
      expect(Book.search('').count).to eq(3)
    end
  end
end
