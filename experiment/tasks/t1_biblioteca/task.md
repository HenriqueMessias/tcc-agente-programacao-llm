# T1 — CRUD de biblioteca

Desenvolva uma aplicação web de gerenciamento de biblioteca com **autores** e **livros**.

## Requisitos funcionais

- Um autor tem um nome.
- Um livro tem título, ano de publicação e pertence a um autor.
- É possível cadastrar, listar, editar e excluir autores.
- É possível cadastrar, listar, editar e excluir livros.
- É possível buscar livros por título (busca parcial).

## Convenção de rotas (obrigatória, para viabilizar avaliação automatizada)

Use rotas RESTful padrão do Rails: `resources :books` e `resources :authors` (rotas `/books`, `/books/new`, `/books/:id/edit`, `/authors`, `/authors/new`, `/authors/:id/edit`, com os verbos HTTP padrão para create/update/destroy). Os parâmetros de formulário devem seguir a convenção `book[title]`, `book[published_year]`, `book[author_id]`, `author[name]`. A busca por título deve aceitar um parâmetro `query` via GET em `/books` (ex.: `/books?query=termo`).

## Critérios de aceitação (congelados antes da execução)

1. Visitar a rota de listagem de livros retorna HTTP 200 e exibe os livros cadastrados.
2. Visitar a rota de listagem de autores retorna HTTP 200 e exibe os autores cadastrados.
3. É possível criar um novo autor através de um formulário, informando um nome.
4. Criar um autor sem nome falha a validação e não persiste o registro.
5. É possível criar um novo livro através de um formulário, associando-o a um autor existente.
6. Criar um livro sem título falha a validação e não persiste o registro.
7. A listagem de livros exibe o nome do autor associado a cada livro.
8. É possível editar um livro existente e as alterações são persistidas.
9. É possível excluir um livro existente.
10. É possível buscar livros por parte do título (busca case-insensitive, parcial) e apenas os livros correspondentes são retornados.
11. Excluir um autor também remove (ou impede a remoção de, se houver bloqueio explícito) os livros associados a ele — a associação entre autor e livro deve ser respeitada.
12. Formulários de criação/edição exibem mensagens de erro de validação quando campos obrigatórios estão ausentes.
