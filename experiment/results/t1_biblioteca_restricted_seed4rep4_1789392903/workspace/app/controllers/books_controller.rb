class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]

  def index
    @query = params[:query]
    @books = Book.includes(:author).search(@query).order(:title)
  end

  def show
  end

  def new
    @book = Book.new
  end

  def edit
  end

  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to books_path, notice: "Livro criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @book.update(book_params)
      redirect_to books_path, notice: "Livro atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "Livro removido com sucesso."
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :published_year, :author_id)
  end
end
