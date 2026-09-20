require 'rails_helper'

RSpec.describe "Authors", type: :request do
  # Critério 2: listagem de autores retorna 200 e exibe autores cadastrados
  describe "GET /authors" do
    it "returns 200 and lists authors" do
      Author.create!(name: "Machado de Assis")
      get authors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Machado de Assis")
    end
  end

  # Critério 3: criar autor via formulário
  describe "POST /authors" do
    it "creates a new author" do
      expect {
        post authors_path, params: { author: { name: "Clarice Lispector" } }
      }.to change(Author, :count).by(1)
      expect(response).to redirect_to(authors_path)
      follow_redirect!
      expect(response.body).to include("Clarice Lispector")
    end

    # Critério 4: criar autor sem nome falha e não persiste
    it "does not create an author without a name" do
      expect {
        post authors_path, params: { author: { name: "" } }
      }.not_to change(Author, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # Critério 12: formulário exibe erros de validação
  describe "GET /authors/new" do
    it "returns 200 with a form" do
      get new_author_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("author[name]")
    end
  end

  describe "GET /authors/:id/edit" do
    it "returns 200 with a form" do
      author = Author.create!(name: "Machado de Assis")
      get edit_author_path(author)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Machado de Assis")
    end
  end

  describe "PATCH /authors/:id" do
    it "updates the author" do
      author = Author.create!(name: "Old Name")
      patch author_path(author), params: { author: { name: "New Name" } }
      expect(response).to redirect_to(authors_path)
      expect(author.reload.name).to eq("New Name")
    end
  end

  # Critério 11: excluir autor remove livros associados
  describe "DELETE /authors/:id" do
    it "deletes the author and its books" do
      author = Author.create!(name: "Machado de Assis")
      author.books.create!(title: "Dom Casmurro")
      expect {
        delete author_path(author)
      }.to change(Author, :count).by(-1).and change(Book, :count).by(-1)
      expect(response).to redirect_to(authors_path)
    end
  end
end
