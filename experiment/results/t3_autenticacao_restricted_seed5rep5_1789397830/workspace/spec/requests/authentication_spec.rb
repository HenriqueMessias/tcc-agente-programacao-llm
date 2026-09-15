require "rails_helper"

RSpec.describe "Autenticação", type: :request do
  def create_user(email: "user@example.com", password: "secret123")
    User.create!(email: email, password: password)
  end

  describe "Critério 1 — GET /signup" do
    it "retorna HTTP 200 com um formulário de cadastro" do
      get "/signup"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="signup-form"')
      expect(response.body).to include('id="user_email"')
      expect(response.body).to include('id="user_password"')
    end
  end

  describe "Critério 2 — Cadastro válido" do
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

  describe "Critério 3 — Email duplicado" do
    it "falha a validação e não cria um segundo registro" do
      create_user(email: "dup@example.com")

      expect {
        post "/signup", params: { user: { email: "dup@example.com", password: "secret123" } }
      }.not_to change(User, :count)

      expect(User.where(email: "dup@example.com").count).to eq(1)
    end
  end

  describe "Critério 4 — Senha vazia ou ausente" do
    it "falha a validação quando a senha está vazia" do
      expect {
        post "/signup", params: { user: { email: "vazio@example.com", password: "" } }
      }.not_to change(User, :count)
    end

    it "falha a validação quando a senha está ausente" do
      expect {
        post "/signup", params: { user: { email: "ausente@example.com" } }
      }.not_to change(User, :count)
    end
  end

  describe "Critério 5 — GET /login" do
    it "retorna HTTP 200 com um formulário de login" do
      get "/login"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="login-form"')
      expect(response.body).to include('id="email"')
      expect(response.body).to include('id="password"')
    end
  end

  describe "Critério 6 — Login correto" do
    it "autentica o usuário e redireciona para fora da página de login" do
      create_user(email: "login@example.com", password: "secret123")

      post "/login", params: { email: "login@example.com", password: "secret123" }

      expect(response).to have_http_status(:redirect)
      expect(response.location).not_to include("/login")
    end
  end

  describe "Critério 7 — Login incorreto" do
    it "não autentica, exibe erro e não retorna 500" do
      create_user(email: "errado@example.com", password: "secret123")

      post "/login", params: { email: "errado@example.com", password: "senhaerrada" }

      expect(response.status).not_to eq(500)
      expect(response.body).to include('id="login-error"')
    end
  end

  describe "Critério 8 — /protected sem autenticação" do
    it "redireciona para /login" do
      get "/protected"
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/login")
    end
  end

  describe "Critério 9 — /protected autenticado" do
    it "retorna HTTP 200 e exibe o conteúdo protegido" do
      create_user(email: "protegido@example.com", password: "secret123")
      post "/login", params: { email: "protegido@example.com", password: "secret123" }

      get "/protected"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="protected-content"')
    end
  end

  describe "Critério 10 — Logout" do
    it "encerra a sessão e /protected volta a redirecionar para /login" do
      create_user(email: "logout@example.com", password: "secret123")
      post "/login", params: { email: "logout@example.com", password: "secret123" }

      delete "/logout"
      expect(response).to have_http_status(:redirect)

      get "/protected"
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/login")
    end
  end
end
