require 'rails_helper'

RSpec.describe 'Authors', type: :request do
  let!(:author) { Author.create!(name: 'Machado de Assis') }

  describe 'GET /authors' do
    it 'returns HTTP 200 and lists authors (criterion 2)' do
      get '/authors'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Machado de Assis')
    end
  end

  describe 'POST /authors' do
    it 'creates a new author (criterion 3)' do
      expect {
        post '/authors', params: { author: { name: 'Clarice Lispector' } }
      }.to change(Author, :count).by(1)

      expect(Author.last.name).to eq('Clarice Lispector')
    end

    it 'does not persist an author without a name (criterion 4)' do
      expect {
        post '/authors', params: { author: { name: '' } }
      }.not_to change(Author, :count)
    end

    it 'shows validation errors when name is missing (criterion 12)' do
      post '/authors', params: { author: { name: '' } }
      expect(response.body).to match(/error|can't be blank|obrigat/i)
    end
  end

  describe 'PATCH /authors/:id' do
    it 'updates an existing author' do
      patch "/authors/#{author.id}", params: { author: { name: 'Joaquim Maria Machado de Assis' } }
      expect(author.reload.name).to eq('Joaquim Maria Machado de Assis')
    end
  end

  describe 'DELETE /authors/:id' do
    it 'removes associated books when the author is deleted (criterion 11)' do
      author.books.create!(title: 'Dom Casmurro')

      expect {
        delete "/authors/#{author.id}"
      }.to change(Author, :count).by(-1).and change(Book, :count).by(-1)
    end
  end
end
