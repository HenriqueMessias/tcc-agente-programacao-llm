require 'rails_helper'

RSpec.describe "Authors", type: :request do
  # Critério 2: listagem de autores retorna 200 e exibe autores cadastrados
  describe "GET /authors" do
    it "retorna HTTP 200 e exibe os autores cadastrados" do
      author = Author.create!(name: "Machado de Assis")

      get authors_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Machado de Assis")
    end
  end

  # Critério 3: criar autor via formulário informando nome
  describe "POST /authors" do
    it "cria um novo autor com nome válido" do
      expect {
        post authors_path, params: { author: { name: "Clarice Lispector" } }
      }.to change(Author, :count).by(1)

      expect(Author.last.name).to eq("Clarice Lispector")
    end
  end

  # Critério 4: criar autor sem nome falha validação e não persiste
  describe "POST /authors sem nome" do
    it "não persiste o registro e exibe erro de validação" do
      expect {
        post authors_path, params: { author: { name: "" } }
      }.not_to change(Author, :count)

      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  # Critério 11: excluir autor remove os livros associados
  describe "DELETE /authors/:id" do
    it "remove o autor e seus livros associados" do
      author = Author.create!(name: "Autor Removível")
      Book.create!(title: "Livro do Autor", author: author)

      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1)

      expect(Book.where(author_id: author.id).count).to eq(0)
    end
  end
end
