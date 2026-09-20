require 'rails_helper'

RSpec.describe 'Books', type: :request do
  let!(:author) { Author.create!(name: 'Machado de Assis') }
  let!(:book) { Book.create!(title: 'Dom Casmurro', published_year: 1899, author: author) }

  describe 'GET /books' do
    it 'returns HTTP 200 and lists books (criterion 1)' do
      get '/books'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
    end

    it 'displays the author name for each book (criterion 7)' do
      get '/books'
      expect(response.body).to include('Machado de Assis')
    end
  end

  describe 'GET /books?query=...' do
    before do
      Book.create!(title: 'O Cortiço', author: author)
    end

    it 'returns only matching books (criterion 10)' do
      get '/books', params: { query: 'casmurro' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
      expect(response.body).not_to include('O Cortiço')
    end

    it 'is case-insensitive and partial (criterion 10)' do
      get '/books', params: { query: 'CASMUR' }
      expect(response.body).to include('Dom Casmurro')
      expect(response.body).not_to include('O Cortiço')
    end
  end

  describe 'POST /books' do
    it 'creates a book associated with an author (criterion 5)' do
      expect {
        post '/books', params: { book: { title: 'Quincas Borba', published_year: 1891, author_id: author.id } }
      }.to change(Book, :count).by(1)

      created = Book.last
      expect(created.title).to eq('Quincas Borba')
      expect(created.author_id).to eq(author.id)
    end

    it 'does not persist a book without a title (criterion 6)' do
      expect {
        post '/books', params: { book: { title: '', author_id: author.id } }
      }.not_to change(Book, :count)
    end

    it 'shows validation errors when title is missing (criterion 12)' do
      post '/books', params: { book: { title: '', author_id: author.id } }
      expect(response.body).to match(/error|can't be blank|obrigat/i)
    end
  end

  describe 'PATCH /books/:id' do
    it 'updates an existing book (criterion 8)' do
      patch "/books/#{book.id}", params: { book: { title: 'Dom Casmurro (edição revisada)' } }
      expect(book.reload.title).to eq('Dom Casmurro (edição revisada)')
    end
  end

  describe 'DELETE /books/:id' do
    it 'deletes an existing book (criterion 9)' do
      expect {
        delete "/books/#{book.id}"
      }.to change(Book, :count).by(-1)
    end
  end
end
