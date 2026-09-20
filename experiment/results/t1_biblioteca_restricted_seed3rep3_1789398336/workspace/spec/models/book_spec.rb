require 'rails_helper'

RSpec.describe Book, type: :model do
  let(:author) { Author.create!(name: 'Machado de Assis') }

  it 'é válido com título e autor' do
    expect(Book.new(title: 'Dom Casmurro', author: author)).to be_valid
  end

  it 'é inválido sem título (critério 6)' do
    book = Book.new(title: nil, author: author)
    expect(book).not_to be_valid
    expect(book.errors[:title]).to be_present
  end

  it 'não persiste sem título (critério 6)' do
    expect { Book.create(title: nil, author: author) }.not_to change(Book, :count)
  end

  it 'pertence a um autor (critério 5)' do
    assoc = Book.reflect_on_association(:author)
    expect(assoc).not_to be_nil
    expect(assoc.macro).to eq(:belongs_to)
  end

  describe 'busca por título (critério 10)' do
    before do
      Book.create!(title: 'Dom Casmurro', author: author)
      Book.create!(title: 'Memórias Póstumas', author: author)
      Book.create!(title: 'O Cortiço', author: author)
    end

    it 'encontra por parte do título (parcial)' do
      results = Book.search_by_title('Casmurro')
      expect(results.map(&:title)).to eq(['Dom Casmurro'])
    end

    it 'é case-insensitive' do
      results = Book.search_by_title('casmurro')
      expect(results.map(&:title)).to eq(['Dom Casmurro'])
    end

    it 'retorna apenas correspondentes' do
      results = Book.search_by_title('Memórias')
      expect(results.map(&:title)).to eq(['Memórias Póstumas'])
    end

    it 'retorna todos quando o termo é vazio' do
      expect(Book.search_by_title('').count).to eq(3)
      expect(Book.search_by_title(nil).count).to eq(3)
    end
  end
end
