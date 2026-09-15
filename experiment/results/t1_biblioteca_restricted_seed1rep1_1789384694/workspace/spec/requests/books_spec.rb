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

  describe "GET /books/new" do
    it "retorna HTTP 200 com o formulário de novo livro" do
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
      }.to change { Book.count }.by(1)

      created = Book.last
      expect(created.title).to eq("Memórias Póstumas")
      expect(created.author_id).to eq(author.id)
    end
  end

  describe "POST /books sem título (critério 6)" do
    it "falha a validação e não persiste o registro" do
      expect {
        post books_path, params: {
          book: { title: "", published_year: 2000, author_id: author.id }
        }
      }.not_to change { Book.count }

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
      book.reload
      expect(book.title).to eq("Dom Casmurro (Edição Revisada)")
      expect(book.published_year).to eq(1900)
    end
  end

  describe "DELETE /books/:id (critério 9)" do
    it "exclui um livro existente" do
      expect {
        delete book_path(book)
      }.to change { Book.count }.by(-1)
    end
  end

  describe "GET /books?query= (critério 10)" do
    let!(:other_book) do
      Book.create!(title: "O Cortiço", published_year: 1890, author: author)
    end

    it "busca parcial case-insensitive e retorna apenas correspondentes" do
      get books_path, params: { query: "casmurro" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dom Casmurro")
      expect(response.body).not_to include("O Cortiço")
    end

    it "busca parcial com termo em maiúsculas" do
      get books_path, params: { query: "CORTIÇO" }
      expect(response.body).to include("O Cortiço")
      expect(response.body).not_to include("Dom Casmurro")
    end
  end

  describe "formulário de criação exibe erros (critério 12)" do
    it "mostra mensagem de erro quando o título está ausente" do
      post books_path, params: {
        book: { title: "", published_year: 2000, author_id: author.id }
      }
      expect(response.body).to match(/error|erro|can't be blank|não pode ficar em branco/i)
    end
  end
end

RSpec.describe "Books edge cases", type: :request do
  let!(:author) { Author.create!(name: "Autor Edge") }

  it "GET /books/:id retorna 200 para livro existente (critério 1)" do
    book = Book.create!(title: "Livro Edge", published_year: 2020, author: author)
    get book_path(book)
    expect(response).to have_http_status(:ok)
  end

  it "GET /books/:id/edit retorna 200 (critério 8)" do
    book = Book.create!(title: "Livro Edge 2", published_year: 2021, author: author)
    get edit_book_path(book)
    expect(response).to have_http_status(:ok)
  end
end

RSpec.describe "Books search edge cases", type: :request do
  let!(:author) { Author.create!(name: "Autor Busca") }

  it "GET /books?query= retorna 200 (critério 10)" do
    Book.create!(title: "Dom Casmurro", published_year: 1899, author: author)
    get books_path, params: { query: "casmurro" }
    expect(response).to have_http_status(:ok)
  end

  it "busca parcial case-insensitive retorna apenas correspondentes (critério 10)" do
    Book.create!(title: "Memórias Póstumas", published_year: 1881, author: author)
    Book.create!(title: "Quincas Borba", published_year: 1891, author: author)
    get books_path, params: { query: "MEMÓRIAS" }
    expect(response.body).to include("Memórias Póstumas")
    expect(response.body).not_to include("Quincas Borba")
  end
end

RSpec.describe "Books edge cases", type: :request do
  it "GET /books/new retorna 200 (critério 5)" do
    get new_book_path
    expect(response).to have_http_status(:ok)
  end

  it "criar livro sem título não persiste (critério 6)" do
    author = Author.create!(name: "Autor Edge2")
    expect {
      post books_path, params: { book: { title: "", published_year: 2000, author_id: author.id } }
    }.not_to change(Book, :count)
  end
end
