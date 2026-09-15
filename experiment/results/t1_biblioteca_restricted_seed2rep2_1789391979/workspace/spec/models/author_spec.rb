require 'rails_helper'

RSpec.describe Author, type: :model do
  it "is valid with a name" do
    expect(Author.new(name: "Machado de Assis")).to be_valid
  end

  it "is invalid without a name" do
    author = Author.new(name: nil)
    expect(author).not_to be_valid
    expect(author.errors[:name]).to be_present
  end

  it "has many books" do
    author = Author.create!(name: "Machado de Assis")
    author.books.create!(title: "Dom Casmurro")
    expect(author.books.count).to eq(1)
  end

  it "destroys associated books when destroyed" do
    author = Author.create!(name: "Machado de Assis")
    author.books.create!(title: "Dom Casmurro")
    expect { author.destroy }.to change(Book, :count).by(-1)
  end
end
