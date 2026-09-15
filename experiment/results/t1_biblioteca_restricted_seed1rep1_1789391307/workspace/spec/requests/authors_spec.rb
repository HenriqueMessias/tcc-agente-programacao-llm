require "rails_helper"

RSpec.describe "Authors", type: :request do
  describe "GET /authors (critério 2)" do
    it "retorna 200 e exibe os autores cadastrados" do
      Author.create!(name: "Machado de Assis")
      Author.create!(name: "Clarice Lispector")

      get authors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Machado de Assis")
      expect(response.body).to include("Clarice Lispector")
    end
  end

  describe "POST /authors (critério 3)" do
    it "cria um novo autor a partir do formulário" do
      expect {
        post authors_path, params: { author: { name: "Novo Autor" } }
      }.to change(Author, :count).by(1)

      expect(Author.last.name).to eq("Novo Autor")
      expect(response).to redirect_to(authors_path)
    end
  end

  describe "POST /authors sem nome (critério 4)" do
    it "não persiste e exibe erro de validação" do
      expect {
        post authors_path, params: { author: { name: "" } }
      }.not_to change(Author, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  describe "GET /authors/new (critério 12)" do
    it "exibe o formulário de criação" do
      get new_author_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("author[name]")
    end
  end

  describe "PATCH /authors/:id" do
    it "edita um autor existente" do
      author = Author.create!(name: "Antigo Nome")
      patch author_path(author), params: { author: { name: "Nome Editado" } }
      expect(author.reload.name).to eq("Nome Editado")
      expect(response).to redirect_to(authors_path)
    end
  end

  describe "DELETE /authors/:id (critério 11)" do
    it "remove o autor e seus livros associados" do
      author = Author.create!(name: "Autor Removido")
      author.books.create!(title: "Livro do Autor")

      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1).and change(Book, :count).by(-1)

      expect(response).to redirect_to(authors_path)
    end
  end
end
