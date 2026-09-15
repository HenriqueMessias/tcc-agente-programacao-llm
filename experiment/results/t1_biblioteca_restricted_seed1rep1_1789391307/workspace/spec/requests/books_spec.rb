require "rails_helper"

RSpec.describe "Books", type: :request do
  let!(:author) { Author.create!(name: "Machado de Assis") }

  describe "GET /books (critério 1)" do
    it "retorna 200 e exibe os livros cadastrados" do
      Book.create!(title: "Dom Casmurro", author: author)

      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
    end
  end

  describe "GET /books exibe o autor (critério 7)" do
    it "mostra o nome do autor associado a cada livro" do
      Book.create!(title: "Dom Casmurro", author: author)

      get books_path
      expect(response.body).to include("Machado de Assis")
    end
  end

  describe "POST /books (critério 5)" do
    it "cria um livro associado a um autor existente" do
      expect {
        post books_path, params: { book: { title: "Dom Casmurro", published_year: 1899, author_id: author.id } }
      }.to change(Book, :count).by(1)

      book = Book.last
      expect(book.title).to eq("Dom Casmurro")
      expect(book.author).to eq(author)
      expect(response).to redirect_to(books_path)
    end
  end

  describe "POST /books sem título (critério 6)" do
    it "não persiste e exibe erro de validação" do
      expect {
        post books_path, params: { book: { title: "", author_id: author.id } }
      }.not_to change(Book, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  describe "GET /books/new (critério 12)" do
    it "exibe o formulário de criação" do
      get new_book_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("book[title]")
    end
  end

  describe "PATCH /books/:id (critério 8)" do
    it "edita um livro existente e persiste as alterações" do
      book = Book.create!(title: "Título Antigo", author: author)

      patch book_path(book), params: { book: { title: "Título Novo", published_year: 1900, author_id: author.id } }

      expect(book.reload.title).to eq("Título Novo")
      expect(book.published_year).to eq(1900)
      expect(response).to redirect_to(books_path)
    end
  end

  describe "DELETE /books/:id (critério 9)" do
    it "exclui um livro existente" do
      book = Book.create!(title: "Livro a Excluir", author: author)

      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)

      expect(response).to redirect_to(books_path)
    end
  end

  describe "GET /books?query= (critério 10)" do
    before do
      Book.create!(title: "Dom Casmurro", author: author)
      Book.create!(title: "Memórias Póstumas", author: author)
      Book.create!(title: "O Cortiço", author: author)
    end

    it "retorna apenas os livros correspondentes (parcial, case-insensitive)" do
      get books_path, params: { query: "casmurro" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
      expect(response.body).not_to include("O Cortiço")
      expect(response.body).not_to include("Memórias Póstumas")
    end
  end
end
