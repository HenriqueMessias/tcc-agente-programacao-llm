require 'rails_helper'

RSpec.describe Author, type: :model do
  it 'é válido com um nome' do
    expect(Author.new(name: 'Machado de Assis')).to be_valid
  end

  it 'é inválido sem nome' do
    author = Author.new(name: nil)
    expect(author).not_to be_valid
    expect(author.errors[:name]).to be_present
  end

  it 'possui associação has_many :books' do
    expect(Author.reflect_on_association(:books).macro).to eq(:has_many)
  end
end
