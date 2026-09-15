class AuthorsController < ApplicationController
  before_action :set_author, only: %i[show edit update destroy]

  def index
    @authors = Author.order(:name)
  end

  def show
  end

  def new
    @author = Author.new
  end

  def edit
  end

  def create
    @author = Author.new(author_params)

    if @author.save
      redirect_to @author, notice: "Autor criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @author.update(author_params)
      redirect_to @author, notice: "Autor atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @author.destroy
    redirect_to authors_url, notice: "Autor removido com sucesso."
  end

  private

  def set_author
    @author = Author.find(params[:id])
  end

  def author_params
    params.require(:author).permit(:name)
  end
end
