require 'rails_helper'

RSpec.describe 'Books', type: :request do
  let!(:author) { Author.create!(name: 'Machado de Assis') }

  describe 'GET /books (criterion 1)' do
    it 'returns HTTP 200 and lists books' do
      Book.create!(title: 'Dom Casmurro', published_year: 1899, author: author)

      get books_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
    end

    it 'displays the author name for each book (criterion 7)' do
      Book.create!(title: 'Dom Casmurro', author: author)

      get books_path

      expect(response.body).to include('Machado de Assis')
    end
  end

  describe 'GET /books/new' do
    it 'renders the new book form' do
      get new_book_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('book[title]')
    end
  end

  describe 'POST /books (criterion 5)' do
    it 'creates a new book associated with an author' do
      expect {
        post books_path, params: { book: { title: 'Memórias Póstumas', published_year: 1881, author_id: author.id } }
      }.to change(Book, :count).by(1)

      book = Book.last
      expect(book.title).to eq('Memórias Póstumas')
      expect(book.author).to eq(author)
    end

    it 'does not persist a book without a title (criterion 6)' do
      expect {
        post books_path, params: { book: { title: '', author_id: author.id } }
      }.not_to change(Book, :count)
    end

    it 'shows validation errors when title is missing (criterion 12)' do
      post books_path, params: { book: { title: '', author_id: author.id } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/title/i)
    end
  end

  describe 'PATCH /books/:id (criterion 8)' do
    it 'updates an existing book and persists changes' do
      book = Book.create!(title: 'Antigo', published_year: 1900, author: author)

      patch book_path(book), params: { book: { title: 'Novo Título', published_year: 1901 } }

      book.reload
      expect(book.title).to eq('Novo Título')
      expect(book.published_year).to eq(1901)
    end
  end

  describe 'DELETE /books/:id (criterion 9)' do
    it 'deletes an existing book' do
      book = Book.create!(title: 'Para Excluir', author: author)

      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
    end
  end

  describe 'GET /books?query= (criterion 10)' do
    before do
      Book.create!(title: 'Dom Casmurro', author: author)
      Book.create!(title: 'Memórias Póstumas', author: author)
      Book.create!(title: 'O Cortiço', author: author)
    end

    it 'returns only matching books for a partial, case-insensitive query' do
      get books_path, params: { query: 'casmurro' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
      expect(response.body).not_to include('O Cortiço')
    end

    it 'is case-insensitive' do
      get books_path, params: { query: 'DOM' }

      expect(response.body).to include('Dom Casmurro')
      expect(response.body).not_to include('O Cortiço')
    end

    it 'matches partial titles' do
      get books_path, params: { query: 'memó' }

      expect(response.body).to include('Memórias Póstumas')
      expect(response.body).not_to include('Dom Casmurro')
    end
  end
end
