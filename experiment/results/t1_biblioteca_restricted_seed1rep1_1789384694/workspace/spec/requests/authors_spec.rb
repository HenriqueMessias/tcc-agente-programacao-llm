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
    it "retorna HTTP 200 com o formulário de novo autor" do
      get new_author_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /authors (critério 3)" do
    it "cria um novo autor informando um nome" do
      expect {
        post authors_path, params: { author: { name: "Clarice Lispector" } }
      }.to change { Author.count }.by(1)

      expect(Author.last.name).to eq("Clarice Lispector")
    end
  end

  describe "POST /authors sem nome (critério 4)" do
    it "falha a validação e não persiste o registro" do
      expect {
        post authors_path, params: { author: { name: "" } }
      }.not_to change { Author.count }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /authors/:id" do
    it "edita um autor existente e persiste as alterações" do
      patch author_path(author), params: { author: { name: "Joaquim Maria Machado de Assis" } }
      expect(author.reload.name).to eq("Joaquim Maria Machado de Assis")
    end
  end

  describe "DELETE /authors/:id (critério 11)" do
    it "remove os livros associados ao excluir o autor" do
      Book.create!(title: "Dom Casmurro", published_year: 1899, author: author)

      expect {
        delete author_path(author)
      }.to change { Author.count }.by(-1)
        .and change { Book.count }.by(-1)
    end
  end

  describe "formulário de criação exibe erros (critério 12)" do
    it "mostra mensagem de erro quando o nome está ausente" do
      post authors_path, params: { author: { name: "" } }
      expect(response.body).to match(/error|erro|can't be blank|não pode ficar em branco/i)
    end
  end
end

RSpec.describe "Authors edge cases", type: :request do
  it "GET /authors/:id/edit retorna 200 (critério 3)" do
    author = Author.create!(name: "Autor Edit")
    get edit_author_path(author)
    expect(response).to have_http_status(:ok)
  end

  it "DELETE /authors/:id remove o autor (critério 11)" do
    author = Author.create!(name: "Autor Del")
    expect { delete author_path(author) }.to change(Author, :count).by(-1)
  end
end

RSpec.describe "Authors edge cases", type: :request do
  it "GET /authors/new retorna 200 (critério 3)" do
    get new_author_path
    expect(response).to have_http_status(:ok)
  end

  it "criar autor sem nome não persiste (critério 4)" do
    expect {
      post authors_path, params: { author: { name: "" } }
    }.not_to change(Author, :count)
  end
end
