require 'rails_helper'

RSpec.describe "Authors", type: :request do
  let!(:author) { Author.create!(name: "Machado de Assis") }

  describe "GET /authors (critério 2)" do
    it "retorna HTTP 200 e exibe os autores cadastrados" do
      get authors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Machado de Assis")
    end
  end

  describe "GET /authors/new" do
    it "retorna HTTP 200" do
      get new_author_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /authors (critério 3)" do
    it "cria um novo autor com nome" do
      expect {
        post authors_path, params: { author: { name: "Clarice Lispector" } }
      }.to change(Author, :count).by(1)

      expect(Author.last.name).to eq("Clarice Lispector")
    end
  end

  describe "POST /authors sem nome (critério 4 e 12)" do
    it "não persiste e exibe mensagem de erro" do
      expect {
        post authors_path, params: { author: { name: "" } }
      }.not_to change(Author, :count)

      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  describe "PATCH /authors/:id" do
    it "edita um autor existente" do
      patch author_path(author), params: { author: { name: "Joaquim Maria Machado de Assis" } }
      expect(author.reload.name).to eq("Joaquim Maria Machado de Assis")
    end
  end

  describe "DELETE /authors/:id (critério 11)" do
    it "exclui o autor e seus livros associados" do
      author.books.create!(title: "Dom Casmurro")

      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1).and change(Book, :count).by(-1)
    end
  end
end
