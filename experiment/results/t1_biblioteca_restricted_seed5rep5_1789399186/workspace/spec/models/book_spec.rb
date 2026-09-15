require 'rails_helper'

RSpec.describe Book, type: :model do
  let(:author) { Author.create!(name: 'Machado de Assis') }

  describe 'validations' do
    it 'is valid with a title and author' do
      book = Book.new(title: 'Dom Casmurro', published_year: 1899, author: author)
      expect(book).to be_valid
    end

    it 'is invalid without a title (criterion 6)' do
      book = Book.new(title: nil, author: author)
      expect(book).not_to be_valid
      expect(book.errors[:title]).to be_present
    end
  end

  describe 'associations' do
    it 'belongs to an author' do
      book = Book.create!(title: 'Dom Casmurro', author: author)
      expect(book.author).to eq(author)
    end
  end
end
