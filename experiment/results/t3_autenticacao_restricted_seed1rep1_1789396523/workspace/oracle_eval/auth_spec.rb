# Testes-oráculo de T3 — independentes do agente. Cada exemplo corresponde a
# um critério de aceitação de tasks/t3_autenticacao/task.md.
require_relative "../spec/rails_helper"

RSpec.describe "Autenticação (oráculo T3)", type: :request do
  before { host! "127.0.0.1" }

  def signup!(email: "user@example.com", password: "senha123")
    post "/signup", params: { user: { email: email, password: password } }
  end

  # Critério 1
  it "critério 1: /signup retorna HTTP 200 com formulário" do
    get "/signup"
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css("#signup-form")).not_to be_nil
  end

  # Critério 2
  it "critério 2: cadastro válido cria o usuário sem senha em texto puro" do
    expect { signup!(email: "a@example.com", password: "senha123") }.to change(User, :count).by(1)
    user = User.order(:id).last
    expect(user.password_digest).not_to eq("senha123")
    expect(user.password_digest).to be_present
  end

  # Critério 3
  it "critério 3: email duplicado não cria um segundo registro" do
    signup!(email: "dup@example.com", password: "senha123")
    expect { signup!(email: "dup@example.com", password: "outrasenha") }.not_to change(User, :count)
  end

  # Critério 4
  it "critério 4: senha vazia falha a validação" do
    expect { signup!(email: "semsenha@example.com", password: "") }.not_to change(User, :count)
  end

  # Critério 5
  it "critério 5: /login retorna HTTP 200 com formulário" do
    get "/login"
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css("#login-form")).not_to be_nil
  end

  # Critério 6
  it "critério 6: login com credenciais corretas autentica e sai da página de login" do
    signup!(email: "login@example.com", password: "senha123")
    post "/login", params: { email: "login@example.com", password: "senha123" }
    expect(response).to have_http_status(:redirect)
    follow_redirect!
    expect(request.path).not_to eq("/login")
  end

  # Critério 7
  it "critério 7: login com senha incorreta não autentica e não gera erro 500" do
    signup!(email: "errado@example.com", password: "senha123")
    post "/login", params: { email: "errado@example.com", password: "senhaerrada" }
    expect(response.status).to be_between(200, 499)
    expect(Nokogiri::HTML(response.body).at_css("#login-error")).not_to be_nil
  end

  # Critério 8
  it "critério 8: /protected sem autenticação redireciona para /login" do
    get "/protected"
    expect(response).to redirect_to("/login")
  end

  # Critério 9
  it "critério 9: /protected com autenticação retorna 200 com o conteúdo protegido" do
    signup!(email: "logado@example.com", password: "senha123")
    get "/protected"
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css("#protected-content")).not_to be_nil
  end

  # Critério 10
  it "critério 10: logout encerra a sessão" do
    signup!(email: "logout@example.com", password: "senha123")
    delete "/logout"
    get "/protected"
    expect(response).to redirect_to("/login")
  end
end
