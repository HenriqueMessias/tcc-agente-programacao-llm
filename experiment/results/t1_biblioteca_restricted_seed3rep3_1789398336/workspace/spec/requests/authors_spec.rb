require 'rails_helper'

RSpec.describe 'Authors', type: :request do
  describe 'GET /authors (critério 2)' do
    it 'retorna 200 e exibe os autores cadastrados' do
      Author.create!(name: 'Machado de Assis')
      Author.create!(name: 'Clarice Lispector')

      get authors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Machado de Assis')
      expect(response.body).to include('Clarice Lispector')
    end
  end

  describe 'GET /authors/new' do
    it 'retorna 200 com formulário' do
      get new_author_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /authors (critério 3)' do
    it 'cria um autor com nome válido' do
      expect {
        post authors_path, params: { author: { name: 'Novo Autor' } }
      }.to change(Author, :count).by(1)

      expect(Author.last.name).to eq('Novo Autor')
    end
  end

  describe 'POST /authors sem nome (critério 4 e 12)' do
    it 'não persiste e exibe erros de validação' do
      expect {
        post authors_path, params: { author: { name: '' } }
      }.not_to change(Author, :count)

      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  describe 'PATCH /authors/:id' do
    it 'atualiza o autor' do
      author = Author.create!(name: 'Antigo')
      patch author_path(author), params: { author: { name: 'Atualizado' } }
      expect(author.reload.name).to eq('Atualizado')
    end
  end

  describe 'DELETE /authors/:id (critério 11)' do
    it 'remove o autor e seus livros associados' do
      author = Author.create!(name: 'Com Livros')
      author.books.create!(title: 'Livro 1')
      author.books.create!(title: 'Livro 2')

      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1).and change(Book, :count).by(-2)
    end
  end
end
