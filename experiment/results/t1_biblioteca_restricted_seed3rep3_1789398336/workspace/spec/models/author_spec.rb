require 'rails_helper'

RSpec.describe Author, type: :model do
  it 'é válido com um nome' do
    expect(Author.new(name: 'Machado de Assis')).to be_valid
  end

  it 'é inválido sem nome (critério 4)' do
    author = Author.new(name: nil)
    expect(author).not_to be_valid
    expect(author.errors[:name]).to be_present
  end

  it 'não persiste sem nome (critério 4)' do
    expect { Author.create(name: nil) }.not_to change(Author, :count)
  end

  it 'possui muitos livros (critério 11)' do
    assoc = Author.reflect_on_association(:books)
    expect(assoc).not_to be_nil
    expect(assoc.macro).to eq(:has_many)
  end

  it 'destrói os livros associados ao ser excluído (critério 11)' do
    author = Author.create!(name: 'Autor com livros')
    author.books.create!(title: 'Livro A')
    author.books.create!(title: 'Livro B')

    expect { author.destroy }.to change(Book, :count).by(-2)
  end
end
