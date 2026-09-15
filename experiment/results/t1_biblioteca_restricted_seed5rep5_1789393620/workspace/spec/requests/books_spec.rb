require 'rails_helper'

RSpec.describe "Books", type: :request do
  let!(:author) { Author.create!(name: "Machado de Assis") }
  let!(:book) do
    Book.create!(title: "Dom Casmurro", published_year: 1899, author: author)
  end

  describe "GET /books (critério 1)" do
    it "retorna HTTP 200 e exibe os livros cadastrados" do
      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
    end
  end

  describe "GET /books/:id" do
    it "retorna HTTP 200 e exibe o livro" do
      get book_path(book)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
    end
  end

  describe "GET /books/new" do
    it "retorna HTTP 200 com formulário de criação" do
      get new_book_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /books (critério 5)" do
    it "cria um novo livro associado a um autor existente" do
      expect {
        post books_path, params: {
          book: { title: "Memórias Póstumas", published_year: 1881, author_id: author.id }
        }
      }.to change(Book, :count).by(1)

      created = Book.last
      expect(created.title).to eq("Memórias Póstumas")
      expect(created.author_id).to eq(author.id)
      expect(response).to have_http_status(:found)
    end
  end

  describe "POST /books sem título (critério 6)" do
    it "falha a validação e não persiste o registro" do
      expect {
        post books_path, params: {
          book: { title: "", published_year: 2000, author_id: author.id }
        }
      }.not_to change(Book, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /books exibe o nome do autor (critério 7)" do
    it "mostra o nome do autor associado a cada livro" do
      get books_path
      expect(response.body).to include("Machado de Assis")
    end
  end

  describe "PATCH /books/:id (critério 8)" do
    it "edita um livro existente e persiste as alterações" do
      patch book_path(book), params: {
        book: { title: "Dom Casmurro (Edição Revisada)", published_year: 1900, author_id: author.id }
      }
      expect(response).to have_http_status(:found)
      book.reload
      expect(book.title).to eq("Dom Casmurro (Edição Revisada)")
      expect(book.published_year).to eq(1900)
    end
  end

  describe "DELETE /books/:id (critério 9)" do
    it "exclui um livro existente" do
      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
      expect(response).to have_http_status(:found)
    end
  end

  describe "GET /books?query= (critério 10)" do
    let!(:other) { Book.create!(title: "O Cortiço", published_year: 1890, author: author) }

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

  describe "GET /books/new exibe erros de validação (critério 12)" do
    it "exibe mensagem de erro quando o título está ausente" do
      post books_path, params: {
        book: { title: "", published_year: 2000, author_id: author.id }
      }
      expect(response.body).to match(/error|erro|can't be blank|não pode ficar em branco/i)
    end
  end
end
