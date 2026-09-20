class BooksController < ApplicationController
  before_action :set_book, only: [:edit, :update, :destroy]

  def index
    @books = Book.includes(:author).search(params[:query]).order(:title)
    @books = Book.includes(:author).order(:title) if params[:query].blank?
  end

  def new
    @book = Book.new
    @authors = Author.all.order(:name)
  end

  def create
    @book = Book.new(book_params)
    @authors = Author.all.order(:name)
    if @book.save
      redirect_to books_path, notice: "Livro criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @authors = Author.all.order(:name)
  end

  def update
    @authors = Author.all.order(:name)
    if @book.update(book_params)
      redirect_to books_path, notice: "Livro atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "Livro removido."
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :published_year, :author_id)
  end
end
