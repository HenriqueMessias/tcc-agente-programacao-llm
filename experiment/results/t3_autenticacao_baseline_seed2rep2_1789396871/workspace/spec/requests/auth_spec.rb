require "rails_helper"

RSpec.describe "Authentication", type: :request do
  def signup(email:, password:)
    post "/signup", params: { user: { email: email, password: password } }
  end

  it "GET /signup returns 200 with signup form" do
    get "/signup"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="signup-form"')
    expect(response.body).to include('id="user_email"')
    expect(response.body).to include('id="user_password"')
  end

  it "creates a user with hashed password" do
    expect { signup(email: "a@b.com", password: "secret123") }.to change(User, :count).by(1)
    user = User.last
    expect(user.password_digest).not_to eq("secret123")
    expect(user.authenticate("secret123")).to be_truthy
  end

  it "rejects duplicate email" do
    User.create!(email: "a@b.com", password: "secret123")
    expect { signup(email: "a@b.com", password: "secret123") }.not_to change(User, :count)
  end

  it "rejects empty password" do
    expect { signup(email: "c@d.com", password: "") }.not_to change(User, :count)
  end

  it "GET /login returns 200 with login form" do
    get "/login"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="login-form"')
    expect(response.body).to include('id="email"')
    expect(response.body).to include('id="password"')
  end

  it "logs in with correct credentials" do
    User.create!(email: "a@b.com", password: "secret123")
    post "/login", params: { email: "a@b.com", password: "secret123" }
    expect(response).to redirect_to("/protected")
  end

  it "fails login with wrong password" do
    User.create!(email: "a@b.com", password: "secret123")
    post "/login", params: { email: "a@b.com", password: "wrong" }
    expect(response).not_to have_http_status(:internal_server_error)
    expect(response.body).to include('id="login-error"')
  end

  it "redirects /protected when not authenticated" do
    get "/protected"
    expect(response).to redirect_to("/login")
  end

  it "shows protected content when authenticated" do
    User.create!(email: "a@b.com", password: "secret123")
    post "/login", params: { email: "a@b.com", password: "secret123" }
    get "/protected"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="protected-content"')
  end

  it "logout ends the session" do
    User.create!(email: "a@b.com", password: "secret123")
    post "/login", params: { email: "a@b.com", password: "secret123" }
    delete "/logout"
    get "/protected"
    expect(response).to redirect_to("/login")
  end
end
