# Testes-oráculo de T1 — escritos pelos pesquisadores, independentes do
# agente. Copiados para workspace/oracle_eval/ e rodados isoladamente contra
# a aplicação final (seção 6.5 do protocolo). Cada exemplo corresponde a um
# critério de aceitação de tasks/t1_biblioteca/task.md.
require_relative "../spec/rails_helper"

# Autoconfiguração independente do que o agente gerou em config/environments/test.rb:
# o Rails 8 bloqueia por padrão hosts não reconhecidos (RSpec usa "www.example.com").
RSpec.describe "Biblioteca (oráculo T1)", type: :request do
  before { host! "127.0.0.1" }

  def create_author!(name: "Autor Teste")
    post authors_path, params: { author: { name: name } }
    Author.order(:id).last
  end

  # Critério 2 e 3
  it "critério 2: lista autores com HTTP 200" do
    get authors_path
    expect(response).to have_http_status(:ok)
  end

  it "critério 3: cria um autor com nome válido" do
    expect { post authors_path, params: { author: { name: "Machado de Assis" } } }.to change(Author, :count).by(1)
  end

  # Critério 4
  it "critério 4: rejeita autor sem nome" do
    expect { post authors_path, params: { author: { name: "" } } }.not_to change(Author, :count)
  end

  # Critério 1
  it "critério 1: lista livros com HTTP 200" do
    get books_path
    expect(response).to have_http_status(:ok)
  end

  # Critério 5
  it "critério 5: cria um livro associado a um autor existente" do
    author = create_author!
    expect { post books_path, params: { book: { title: "Dom Casmurro", published_year: 1899, author_id: author.id } } }.to change(Book, :count).by(1)
  end

  # Critério 6
  it "critério 6: rejeita livro sem título" do
    author = create_author!
    expect { post books_path, params: { book: { title: "", author_id: author.id } } }.not_to change(Book, :count)
  end

  # Critério 7
  it "critério 7: listagem de livros exibe o nome do autor associado" do
    author = create_author!(name: "Clarice Lispector")
    post books_path, params: { book: { title: "A Hora da Estrela", author_id: author.id } }
    get books_path
    expect(response.body).to include("Clarice Lispector")
  end

  # Critério 8
  it "critério 8: edita um livro existente" do
    author = create_author!
    post books_path, params: { book: { title: "Título Original", author_id: author.id } }
    book = Book.order(:id).last
    patch book_path(book), params: { book: { title: "Título Editado", author_id: author.id } }
    expect(book.reload.title).to eq("Título Editado")
  end

  # Critério 9
  it "critério 9: exclui um livro existente" do
    author = create_author!
    post books_path, params: { book: { title: "Livro a Excluir", author_id: author.id } }
    book = Book.order(:id).last
    expect { delete book_path(book) }.to change(Book, :count).by(-1)
  end

  # Critério 10
  it "critério 10: busca livros por parte do título" do
    author = create_author!
    post books_path, params: { book: { title: "Grande Sertão: Veredas", author_id: author.id } }
    post books_path, params: { book: { title: "Vidas Secas", author_id: author.id } }
    get books_path, params: { query: "Sertão" }
    expect(response.body).to include("Grande Sertão: Veredas")
    expect(response.body).not_to include("Vidas Secas")
  end

  # Critério 11
  it "critério 11: relação autor-livro é respeitada ao excluir o autor" do
    author = create_author!
    post books_path, params: { book: { title: "Livro Vinculado", author_id: author.id } }
    book = Book.order(:id).last
    delete author_path(author)
    expect(Book.exists?(book.id)).to be(false)
  end

  # Critério 12
  it "critério 12: formulário de livro exibe erro de validação quando título ausente" do
    author = create_author!
    post books_path, params: { book: { title: "", author_id: author.id } }
    expect(response.body.downcase).to match(/t[íi]tulo|title|blank|obrigat[óo]rio/)
  end
end
