require 'rails_helper'

RSpec.describe 'Books', type: :request do
  let!(:author) { Author.create!(name: 'Machado de Assis') }

  describe 'GET /books (critério 1 e 7)' do
    it 'retorna 200 e exibe os livros com o nome do autor' do
      Book.create!(title: 'Dom Casmurro', published_year: 1899, author: author)

      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
      expect(response.body).to include('Machado de Assis')
    end
  end

  describe 'GET /books/new' do
    it 'retorna 200 com formulário' do
      get new_book_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /books (critério 5)' do
    it 'cria um livro associado a um autor existente' do
      expect {
        post books_path, params: { book: { title: 'Dom Casmurro', published_year: 1899, author_id: author.id } }
      }.to change(Book, :count).by(1)

      book = Book.last
      expect(book.title).to eq('Dom Casmurro')
      expect(book.author).to eq(author)
    end
  end

  describe 'POST /books sem título (critério 6 e 12)' do
    it 'não persiste e exibe erros de validação' do
      expect {
        post books_path, params: { book: { title: '', author_id: author.id } }
      }.not_to change(Book, :count)

      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  describe 'PATCH /books/:id (critério 8)' do
    it 'edita e persiste as alterações' do
      book = Book.create!(title: 'Antigo', author: author)
      patch book_path(book), params: { book: { title: 'Novo Título' } }
      expect(book.reload.title).to eq('Novo Título')
    end
  end

  describe 'DELETE /books/:id (critério 9)' do
    it 'exclui o livro' do
      book = Book.create!(title: 'Para Excluir', author: author)
      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
    end
  end

  describe 'GET /books?query=termo (critério 10)' do
    before do
      Book.create!(title: 'Dom Casmurro', author: author)
      Book.create!(title: 'Memórias Póstumas', author: author)
    end

    it 'retorna apenas os livros correspondentes (parcial, case-insensitive)' do
      get books_path, params: { query: 'casmurro' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
      expect(response.body).not_to include('Memórias Póstumas')
    end
  end
end
