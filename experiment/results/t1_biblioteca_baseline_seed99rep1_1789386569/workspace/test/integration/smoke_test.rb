require "test_helper"

class SmokeTest < ActionDispatch::IntegrationTest
  test "full flow" do
    # create author
    assert_difference("Author.count", 1) do
      post authors_path, params: { author: { name: "Machado" } }
    end
    author = Author.last

    # invalid author
    assert_no_difference("Author.count") do
      post authors_path, params: { author: { name: "" } }
    end
    assert_response :unprocessable_entity

    # create book
    assert_difference("Book.count", 1) do
      post books_path, params: { book: { title: "Dom Casmurro", published_year: 1899, author_id: author.id } }
    end
    book = Book.last

    # invalid book
    assert_no_difference("Book.count") do
      post books_path, params: { book: { title: "", author_id: author.id } }
    end
    assert_response :unprocessable_entity

    # index shows author name
    get books_path
    assert_response :success
    assert_match "Machado", response.body

    # search
    get books_path, params: { query: "casmurro" }
    assert_response :success
    assert_match "Dom Casmurro", response.body

    get books_path, params: { query: "zzz" }
    assert_no_match "Dom Casmurro", response.body

    # edit
    patch book_path(book), params: { book: { title: "Dom Casmurro 2" } }
    assert_equal "Dom Casmurro 2", book.reload.title

    # delete author cascades
    assert_difference("Book.count", -1) do
      delete author_path(author)
    end
  end
end
