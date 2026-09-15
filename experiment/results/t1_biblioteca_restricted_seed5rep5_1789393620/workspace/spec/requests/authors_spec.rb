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
    it "retorna HTTP 200 com formulário de criação" do
      get new_author_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /authors (critério 3)" do
    it "cria um novo autor informando um nome" do
      expect {
        post authors_path, params: { author: { name: "Clarice Lispector" } }
      }.to change(Author, :count).by(1)

      expect(Author.last.name).to eq("Clarice Lispector")
      expect(response).to have_http_status(:found)
    end
  end

  describe "POST /authors sem nome (critério 4)" do
    it "falha a validação e não persiste o registro" do
      expect {
        post authors_path, params: { author: { name: "" } }
      }.not_to change(Author, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /authors/:id" do
    it "edita um autor existente e persiste as alterações" do
      patch author_path(author), params: { author: { name: "Joaquim Maria Machado de Assis" } }
      expect(response).to have_http_status(:found)
      expect(author.reload.name).to eq("Joaquim Maria Machado de Assis")
    end
  end

  describe "DELETE /authors/:id (critério 11)" do
    it "remove os livros associados ao excluir o autor" do
      Book.create!(title: "Dom Casmurro", published_year: 1899, author: author)

      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1).and change(Book, :count).by(-1)

      expect(response).to have_http_status(:found)
    end
  end

  describe "POST /authors exibe erros de validação (critério 12)" do
    it "exibe mensagem de erro quando o nome está ausente" do
      post authors_path, params: { author: { name: "" } }
      expect(response.body).to match(/error|erro|can't be blank|não pode ficar em branco/i)
    end
  end
end
