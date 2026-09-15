require "rails_helper"

RSpec.describe "Autenticação", type: :request do
  # Critério 1
  describe "GET /signup" do
    it "retorna HTTP 200 com um formulário de cadastro" do
      get "/signup"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="signup-form"')
      expect(response.body).to include('id="user_email"')
      expect(response.body).to include('id="user_password"')
    end
  end

  # Critério 2
  describe "POST /signup com dados válidos" do
    it "cria o registro e não armazena a senha em texto puro" do
      expect {
        post "/signup", params: { user: { email: "novo@example.com", password: "secret123" } }
      }.to change(User, :count).by(1)

      user = User.find_by(email: "novo@example.com")
      expect(user).to be_present
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq("secret123")
    end
  end

  # Critério 3
  describe "POST /signup com email já cadastrado" do
    before { User.create!(email: "dup@example.com", password: "secret123") }

    it "falha a validação e não cria um segundo registro" do
      expect {
        post "/signup", params: { user: { email: "dup@example.com", password: "outrasenha" } }
      }.not_to change(User, :count)
    end
  end

  # Critério 4
  describe "POST /signup com senha vazia ou ausente" do
    it "falha a validação com senha vazia" do
      expect {
        post "/signup", params: { user: { email: "vazio@example.com", password: "" } }
      }.not_to change(User, :count)
    end

    it "falha a validação com senha ausente" do
      expect {
        post "/signup", params: { user: { email: "ausente@example.com" } }
      }.not_to change(User, :count)
    end
  end

  # Critério 5
  describe "GET /login" do
    it "retorna HTTP 200 com um formulário de login" do
      get "/login"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="login-form"')
      expect(response.body).to include('id="email"')
      expect(response.body).to include('id="password"')
    end
  end

  # Critério 6
  describe "POST /login com credenciais corretas" do
    before { User.create!(email: "user@example.com", password: "secret123") }

    it "autentica o usuário e redireciona para fora da página de login" do
      post "/login", params: { email: "user@example.com", password: "secret123" }
      expect(response).to have_http_status(:found)
      expect(response.location).not_to include("/login")
    end
  end

  # Critério 7
  describe "POST /login com senha incorreta" do
    before { User.create!(email: "user@example.com", password: "secret123") }

    it "não autentica, exibe erro e não retorna HTTP 500" do
      post "/login", params: { email: "user@example.com", password: "errada" }
      expect(response.status).not_to eq(500)
      expect(response.body).to include('id="login-error"')
    end
  end

  # Critério 8
  describe "GET /protected sem autenticação" do
    it "redireciona para /login" do
      get "/protected"
      expect(response).to have_http_status(:found)
      expect(response.location).to include("/login")
    end
  end

  # Critério 9
  describe "GET /protected autenticado" do
    before { User.create!(email: "user@example.com", password: "secret123") }

    it "retorna HTTP 200 e exibe o conteúdo protegido" do
      post "/login", params: { email: "user@example.com", password: "secret123" }
      get "/protected"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="protected-content"')
    end
  end

  # Critério 10
  describe "DELETE /logout" do
    before { User.create!(email: "user@example.com", password: "secret123") }

    it "encerra a sessão: /protected volta a redirecionar para /login" do
      post "/login", params: { email: "user@example.com", password: "secret123" }
      delete "/logout"
      get "/protected"
      expect(response).to have_http_status(:found)
      expect(response.location).to include("/login")
    end
  end
end
