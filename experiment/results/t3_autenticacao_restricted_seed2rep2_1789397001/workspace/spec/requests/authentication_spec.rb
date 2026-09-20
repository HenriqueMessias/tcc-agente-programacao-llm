require "rails_helper"

RSpec.describe "Autenticação", type: :request do
  def create_user(email: "user@example.com", password: "secret123")
    User.create!(email: email, password: password)
  end

  describe "GET /signup" do
    it "retorna 200 com o formulário de cadastro" do
      get "/signup"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="signup-form"')
      expect(response.body).to include('id="user_email"')
      expect(response.body).to include('id="user_password"')
    end
  end

  describe "POST /signup" do
    it "cria o usuário com email e senha válidos (senha não em texto puro)" do
      expect {
        post "/signup", params: { user: { email: "novo@example.com", password: "secret123" } }
      }.to change(User, :count).by(1)

      user = User.find_by(email: "novo@example.com")
      expect(user).to be_present
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq("secret123")
    end

    it "falha com email já cadastrado e não cria segundo registro" do
      create_user(email: "dup@example.com")

      expect {
        post "/signup", params: { user: { email: "dup@example.com", password: "secret123" } }
      }.not_to change(User, :count)

      expect(response).not_to have_http_status(:internal_server_error)
    end

    it "falha com senha vazia" do
      expect {
        post "/signup", params: { user: { email: "vazio@example.com", password: "" } }
      }.not_to change(User, :count)

      expect(response).not_to have_http_status(:internal_server_error)
    end

    it "falha com senha ausente" do
      expect {
        post "/signup", params: { user: { email: "ausente@example.com" } }
      }.not_to change(User, :count)

      expect(response).not_to have_http_status(:internal_server_error)
    end
  end

  describe "GET /login" do
    it "retorna 200 com o formulário de login" do
      get "/login"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="login-form"')
      expect(response.body).to include('id="email"')
      expect(response.body).to include('id="password"')
    end
  end

  describe "POST /login" do
    it "autentica com credenciais corretas e redireciona para fora do login" do
      create_user(email: "ok@example.com", password: "secret123")

      post "/login", params: { email: "ok@example.com", password: "secret123" }

      expect(response).to have_http_status(:redirect)
      expect(response.location).not_to include("/login")
    end

    it "não autentica com senha incorreta e exibe erro sem 500" do
      create_user(email: "errado@example.com", password: "secret123")

      post "/login", params: { email: "errado@example.com", password: "senhaerrada" }

      expect(response).not_to have_http_status(:internal_server_error)
      expect(response.body).to include('id="login-error"')
    end
  end

  describe "GET /protected" do
    it "redireciona para /login quando não autenticado" do
      get "/protected"
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/login")
    end

    it "retorna 200 e exibe conteúdo protegido quando autenticado" do
      create_user(email: "auth@example.com", password: "secret123")
      post "/login", params: { email: "auth@example.com", password: "secret123" }

      get "/protected"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="protected-content"')
    end
  end

  describe "DELETE /logout" do
    it "encerra a sessão e /protected volta a redirecionar para /login" do
      create_user(email: "logout@example.com", password: "secret123")
      post "/login", params: { email: "logout@example.com", password: "secret123" }

      delete "/logout"

      get "/protected"
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/login")
    end
  end
end
