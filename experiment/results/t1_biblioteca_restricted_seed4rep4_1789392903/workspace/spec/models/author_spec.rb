require 'rails_helper'

RSpec.describe Author, type: :model do
  describe 'validations' do
    it 'is valid with a name' do
      author = Author.new(name: 'Machado de Assis')
      expect(author).to be_valid
    end

    it 'is invalid without a name' do
      author = Author.new(name: nil)
      expect(author).not_to be_valid
      expect(author.errors[:name]).to be_present
    end
  end

  describe 'associations' do
    it 'has many books' do
      author = Author.create!(name: 'Machado de Assis')
      book = author.books.create!(title: 'Dom Casmurro')
      expect(author.books).to include(book)
    end

    it 'destroys associated books when destroyed' do
      author = Author.create!(name: 'Machado de Assis')
      author.books.create!(title: 'Dom Casmurro')

      expect { author.destroy }.to change(Book, :count).by(-1)
    end
  end
end
