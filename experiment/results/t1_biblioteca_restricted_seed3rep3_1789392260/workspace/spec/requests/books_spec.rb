require 'rails_helper'

RSpec.describe "Books", type: :request do
  let!(:author) { Author.create!(name: "J. R. R. Tolkien") }

  # Critério 1: listagem de livros retorna 200 e exibe livros cadastrados
  describe "GET /books" do
    it "retorna HTTP 200 e exibe os livros cadastrados" do
      Book.create!(title: "O Hobbit", published_year: 1937, author: author)

      get books_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("O Hobbit")
    end
  end

  # Critério 7: listagem exibe o nome do autor associado
  describe "GET /books exibindo autor" do
    it "exibe o nome do autor associado a cada livro" do
      Book.create!(title: "O Senhor dos Anéis", published_year: 1954, author: author)

      get books_path

      expect(response.body).to include("J. R. R. Tolkien")
    end
  end

  # Critério 5: criar livro associado a autor existente
  describe "POST /books" do
    it "cria um novo livro associado a um autor existente" do
      expect {
        post books_path, params: { book: { title: "O Silmarillion", published_year: 1977, author_id: author.id } }
      }.to change(Book, :count).by(1)

      book = Book.last
      expect(book.title).to eq("O Silmarillion")
      expect(book.author_id).to eq(author.id)
    end
  end

  # Critério 6: criar livro sem título falha validação e não persiste
  describe "POST /books sem título" do
    it "não persiste o registro e exibe erro de validação" do
      expect {
        post books_path, params: { book: { title: "", published_year: 2000, author_id: author.id } }
      }.not_to change(Book, :count)

      expect(response.body).to match(/error|erro|can't be blank|não pode/i)
    end
  end

  # Critério 8: editar livro existente persiste alterações
  describe "PATCH /books/:id" do
    it "atualiza o livro e persiste as alterações" do
      book = Book.create!(title: "Título Antigo", published_year: 1900, author: author)

      patch book_path(book), params: { book: { title: "Título Novo", published_year: 1901, author_id: author.id } }

      book.reload
      expect(book.title).to eq("Título Novo")
      expect(book.published_year).to eq(1901)
    end
  end

  # Critério 9: excluir livro existente
  describe "DELETE /books/:id" do
    it "remove o livro" do
      book = Book.create!(title: "Livro a Excluir", author: author)

      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
    end
  end

  # Critério 10: busca parcial case-insensitive por título
  describe "GET /books?query=termo" do
    it "retorna apenas os livros correspondentes (parcial, case-insensitive)" do
      matching = Book.create!(title: "O Hobbit", author: author)
      other    = Book.create!(title: "Dom Casmurro", author: author)

      get books_path, params: { query: "hobbit" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("O Hobbit")
      expect(response.body).not_to include("Dom Casmurro")
    end

    it "encontra por parte do título independente de maiúsculas/minúsculas" do
      Book.create!(title: "O Hobbit", author: author)

      get books_path, params: { query: "HOBB" }

      expect(response.body).to include("O Hobbit")
    end
  end

  # Critério 12: formulário de criação exibe erros de validação
  describe "GET /books/new" do
    it "renderiza o formulário de criação" do
      get new_book_path
      expect(response).to have_http_status(:ok)
    end
  end
end
