require 'rails_helper'

RSpec.describe Book, type: :model do
  let(:author) { Author.create!(name: 'Machado de Assis') }

  it 'é válido com título e autor' do
    expect(Book.new(title: 'Dom Casmurro', author: author)).to be_valid
  end

  it 'é inválido sem título' do
    book = Book.new(title: nil, author: author)
    expect(book).not_to be_valid
    expect(book.errors[:title]).to be_present
  end

  it 'é inválido sem autor' do
    book = Book.new(title: 'Dom Casmurro', author: nil)
    expect(book).not_to be_valid
  end

  it 'possui associação belongs_to :author' do
    expect(Book.reflect_on_association(:author).macro).to eq(:belongs_to)
  end
end
