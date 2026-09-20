# T3 — Formulário com autenticação

Desenvolva um sistema simples de cadastro, login e uma página protegida por autenticação.

## Requisitos funcionais

- Um usuário tem email e senha (armazenada com hash, nunca em texto puro).
- É possível cadastrar um novo usuário informando email e senha.
- É possível fazer login com email e senha cadastrados, criando uma sessão.
- É possível fazer logout, encerrando a sessão.
- Existe uma página protegida que só pode ser acessada por um usuário autenticado; sem autenticação, o acesso deve redirecionar para o login.

## Convenção de rotas (obrigatória, para viabilizar avaliação automatizada)

- Cadastro: `GET /signup` (formulário) e `POST /signup` (criação), com parâmetros `user[email]` e `user[password]`.
- Login: `GET /login` (formulário) e `POST /login` (autenticação), com parâmetros `email` e `password` (não aninhados).
- Logout: `DELETE /logout`.
- Página protegida: `GET /protected`.
- O formulário de cadastro deve ter `id="signup-form"`, com campos `id="user_email"` e `id="user_password"`.
- O formulário de login deve ter `id="login-form"`, com campos `id="email"` e `id="password"`.
- Em caso de erro de autenticação, deve existir um elemento com `id="login-error"`.
- A página protegida deve ter um elemento raiz com `id="protected-content"`.

## Critérios de aceitação (congelados antes da execução)

1. Visitar `/signup` retorna HTTP 200 com um formulário de cadastro.
2. Cadastrar um usuário com email e senha válidos cria o registro (a senha não é armazenada em texto puro).
3. Cadastrar um usuário com um email já cadastrado falha a validação e não cria um segundo registro.
4. Cadastrar um usuário com senha vazia ou ausente falha a validação.
5. Visitar `/login` retorna HTTP 200 com um formulário de login.
6. Login com email e senha corretos autentica o usuário (cria uma sessão) e redireciona para fora da página de login.
7. Login com senha incorreta não autentica e exibe uma mensagem de erro, sem lançar erro HTTP 500.
8. Visitar `/protected` sem estar autenticado redireciona para `/login`.
9. Visitar `/protected` estando autenticado retorna HTTP 200 e exibe o conteúdo protegido.
10. Fazer logout encerra a sessão: uma tentativa subsequente de acessar `/protected` volta a redirecionar para `/login`.
