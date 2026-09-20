require 'rails_helper'

RSpec.describe "Books", type: :request do
  let!(:author) { Author.create!(name: "Machado de Assis") }

  # Critério 1: listagem de livros retorna 200 e exibe livros
  describe "GET /books" do
    it "returns 200 and lists books" do
      Book.create!(title: "Dom Casmurro", author: author)
      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
    end

    # Critério 7: exibe o nome do autor associado
    it "displays the author name for each book" do
      Book.create!(title: "Dom Casmurro", author: author)
      get books_path
      expect(response.body).to include("Machado de Assis")
    end

    # Critério 10: busca parcial case-insensitive
    it "filters books by partial title (case-insensitive)" do
      Book.create!(title: "Dom Casmurro", author: author)
      Book.create!(title: "Memórias Póstumas", author: author)
      get books_path, params: { query: "casmurro" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
      expect(response.body).not_to include("Memórias Póstumas")
    end
  end

  # Critério 5: criar livro associado a autor existente
  describe "POST /books" do
    it "creates a new book associated with an author" do
      expect {
        post books_path, params: { book: { title: "Dom Casmurro", published_year: 1899, author_id: author.id } }
      }.to change(Book, :count).by(1)
      expect(response).to redirect_to(books_path)
      book = Book.last
      expect(book.author).to eq(author)
    end

    # Critério 6: criar livro sem título falha e não persiste
    it "does not create a book without a title" do
      expect {
        post books_path, params: { book: { title: "", author_id: author.id } }
      }.not_to change(Book, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /books/new" do
    it "returns 200 with a form" do
      get new_book_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("book[title]")
    end
  end

  describe "GET /books/:id/edit" do
    it "returns 200 with a form" do
      book = Book.create!(title: "Dom Casmurro", author: author)
      get edit_book_path(book)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
    end
  end

  # Critério 8: editar livro persiste alterações
  describe "PATCH /books/:id" do
    it "updates the book" do
      book = Book.create!(title: "Old Title", author: author)
      patch book_path(book), params: { book: { title: "New Title" } }
      expect(response).to redirect_to(books_path)
      expect(book.reload.title).to eq("New Title")
    end
  end

  # Critério 9: excluir livro
  describe "DELETE /books/:id" do
    it "deletes the book" do
      book = Book.create!(title: "Dom Casmurro", author: author)
      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
      expect(response).to redirect_to(books_path)
    end
  end
end
