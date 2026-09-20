class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]

  def index
    @books = Book.includes(:author)
    if params[:query].present?
      @books = @books.search_by_title(params[:query])
    end
    @books = @books.order(:title)
  end

  def show
  end

  def new
    @book = Book.new
    load_authors
  end

  def edit
    load_authors
  end

  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book, notice: "Livro criado com sucesso."
    else
      load_authors
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: "Livro atualizado com sucesso."
    else
      load_authors
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "Livro excluído com sucesso."
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def load_authors
    @authors = Author.order(:name)
  end

  def book_params
    params.require(:book).permit(:title, :published_year, :author_id)
  end
end
