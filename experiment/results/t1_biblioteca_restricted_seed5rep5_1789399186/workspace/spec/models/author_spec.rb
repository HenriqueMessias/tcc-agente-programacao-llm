require 'rails_helper'

RSpec.describe Author, type: :model do
  describe 'validations' do
    it 'is valid with a name' do
      author = Author.new(name: 'Machado de Assis')
      expect(author).to be_valid
    end

    it 'is invalid without a name (criterion 4)' do
      author = Author.new(name: nil)
      expect(author).not_to be_valid
      expect(author.errors[:name]).to be_present
    end
  end

  describe 'associations' do
    it 'has many books' do
      author = Author.create!(name: 'Autora')
      book = author.books.create!(title: 'Livro')
      expect(author.books).to include(book)
    end

    it 'destroys associated books when destroyed (criterion 11)' do
      author = Author.create!(name: 'Autora')
      author.books.create!(title: 'Livro A')
      author.books.create!(title: 'Livro B')

      expect { author.destroy }.to change(Book, :count).by(-2)
    end
  end
end
