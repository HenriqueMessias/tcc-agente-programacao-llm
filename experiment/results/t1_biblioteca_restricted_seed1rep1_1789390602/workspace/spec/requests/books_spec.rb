require 'rails_helper'

RSpec.describe "Books", type: :request do
  let!(:author) { Author.create!(name: "Machado de Assis") }
  let!(:book) { Book.create!(title: "Dom Casmurro", published_year: 1899, author: author) }

  describe "GET /books (critério 1)" do
    it "retorna HTTP 200 e exibe os livros cadastrados" do
      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
    end
  end

  describe "GET /books exibe o nome do autor (critério 7)" do
    it "mostra o nome do autor associado a cada livro" do
      get books_path
      expect(response.body).to include("Machado de Assis")
    end
  end

  describe "GET /books/new" do
    it "retorna HTTP 200" do
      get new_book_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /books (critério 5)" do
    it "cria um livro associado a um autor existente" do
      expect {
        post books_path, params: { book: { title: "Memórias Póstumas", published_year: 1881, author_id: author.id } }
      }.to change(Book, :count).by(1)

      created = Book.last
      expect(created.title).to eq("Memórias Póstumas")
      expect(created.author).to eq(author)
    end
  end

  describe "POST /books sem título (critério 6 e 12)" do
    it "não persiste e exibe mensagem de erro" do
      expect {
        post books_path, params: { book: { title: "", author_id: author.id } }
      }.not_to change(Book, :count)

      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  describe "PATCH /books/:id (critério 8)" do
    it "edita um livro existente e persiste as alterações" do
      patch book_path(book), params: { book: { title: "Dom Casmurro (Edição Revisada)" } }
      expect(book.reload.title).to eq("Dom Casmurro (Edição Revisada)")
    end
  end

  describe "DELETE /books/:id (critério 9)" do
    it "exclui um livro existente" do
      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
    end
  end

  describe "GET /books?query= (critério 10)" do
    let!(:other_book) { Book.create!(title: "O Cortiço", published_year: 1890, author: author) }

    it "busca parcial case-insensitive e retorna apenas correspondentes" do
      get books_path, params: { query: "casmurro" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
      expect(response.body).not_to include("O Cortiço")
    end

    it "busca parcial por parte do título" do
      get books_path, params: { query: "cort" }
      expect(response.body).to include("O Cortiço")
      expect(response.body).not_to include("Dom Casmurro")
    end
  end
end
