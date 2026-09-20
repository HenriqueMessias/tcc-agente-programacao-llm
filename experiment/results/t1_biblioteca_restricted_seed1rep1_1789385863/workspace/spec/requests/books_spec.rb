require 'rails_helper'

RSpec.describe 'Books', type: :request do
  let!(:author) { Author.create!(name: 'Machado de Assis') }

  describe 'GET /books' do
    it 'retorna 200 e exibe os livros cadastrados' do
      Book.create!(title: 'Dom Casmurro', author: author)
      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
    end

    it 'exibe o nome do autor associado a cada livro' do
      Book.create!(title: 'Dom Casmurro', author: author)
      get books_path
      expect(response.body).to include('Machado de Assis')
    end
  end

  describe 'POST /books' do
    it 'cria um novo livro associado a um autor existente' do
      expect {
        post books_path, params: { book: { title: 'Dom Casmurro', published_year: 1899, author_id: author.id } }
      }.to change(Book, :count).by(1)
      expect(response).to redirect_to(books_path)
    end

    it 'não cria livro sem título' do
      expect {
        post books_path, params: { book: { title: '', author_id: author.id } }
      }.not_to change(Book, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /books/:id' do
    it 'edita um livro existente e persiste as alterações' do
      book = Book.create!(title: 'Título Antigo', author: author)
      patch book_path(book), params: { book: { title: 'Título Novo' } }
      expect(book.reload.title).to eq('Título Novo')
    end
  end

  describe 'DELETE /books/:id' do
    it 'exclui um livro existente' do
      book = Book.create!(title: 'Para Excluir', author: author)
      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
    end
  end

  describe 'GET /books?query=termo' do
    it 'busca livros por parte do título, case-insensitive' do
      Book.create!(title: 'Dom Casmurro', author: author)
      Book.create!(title: 'Memórias Póstumas', author: author)
      get books_path, params: { query: 'casmurro' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dom Casmurro')
      expect(response.body).not_to include('Memórias Póstumas')
    end
  end
end
