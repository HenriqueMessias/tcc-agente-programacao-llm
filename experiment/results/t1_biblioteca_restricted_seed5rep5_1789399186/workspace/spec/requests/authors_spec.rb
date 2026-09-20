require 'rails_helper'

RSpec.describe 'Authors', type: :request do
  describe 'GET /authors (criterion 2)' do
    it 'returns HTTP 200 and lists authors' do
      Author.create!(name: 'Machado de Assis')
      Author.create!(name: 'Clarice Lispector')

      get authors_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Machado de Assis')
      expect(response.body).to include('Clarice Lispector')
    end
  end

  describe 'GET /authors/new' do
    it 'renders the new author form' do
      get new_author_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('author[name]')
    end
  end

  describe 'POST /authors (criterion 3)' do
    it 'creates a new author with a name' do
      expect {
        post authors_path, params: { author: { name: 'Novo Autor' } }
      }.to change(Author, :count).by(1)

      expect(Author.last.name).to eq('Novo Autor')
    end

    it 'does not persist an author without a name (criterion 4)' do
      expect {
        post authors_path, params: { author: { name: '' } }
      }.not_to change(Author, :count)
    end

    it 'shows validation errors when name is missing (criterion 12)' do
      post authors_path, params: { author: { name: '' } }
      expect(response.body).to match(/name/i)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /authors/:id' do
    it 'updates an existing author' do
      author = Author.create!(name: 'Antigo')
      patch author_path(author), params: { author: { name: 'Atualizado' } }
      expect(author.reload.name).to eq('Atualizado')
    end
  end

  describe 'DELETE /authors/:id (criterion 11)' do
    it 'deletes the author and its associated books' do
      author = Author.create!(name: 'Com Livros')
      author.books.create!(title: 'Livro 1')
      author.books.create!(title: 'Livro 2')

      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1).and change(Book, :count).by(-2)
    end
  end
end
