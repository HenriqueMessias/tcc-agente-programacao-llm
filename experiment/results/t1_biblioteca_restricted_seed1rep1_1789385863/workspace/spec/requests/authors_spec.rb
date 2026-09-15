require 'rails_helper'

RSpec.describe 'Authors', type: :request do
  describe 'GET /authors' do
    it 'retorna 200 e exibe os autores cadastrados' do
      Author.create!(name: 'Machado de Assis')
      get authors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Machado de Assis')
    end
  end

  describe 'POST /authors' do
    it 'cria um novo autor com nome válido' do
      expect {
        post authors_path, params: { author: { name: 'Clarice Lispector' } }
      }.to change(Author, :count).by(1)
      expect(response).to redirect_to(authors_path)
    end

    it 'não cria autor sem nome' do
      expect {
        post authors_path, params: { author: { name: '' } }
      }.not_to change(Author, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /authors/:id' do
    it 'edita um autor existente' do
      author = Author.create!(name: 'Nome Antigo')
      patch author_path(author), params: { author: { name: 'Nome Novo' } }
      expect(author.reload.name).to eq('Nome Novo')
    end
  end

  describe 'DELETE /authors/:id' do
    it 'exclui o autor e seus livros associados' do
      author = Author.create!(name: 'Autor com Livros')
      Book.create!(title: 'Livro do Autor', author: author)
      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1)
      expect(Book.where(author_id: author.id)).to be_empty
    end
  end
end
