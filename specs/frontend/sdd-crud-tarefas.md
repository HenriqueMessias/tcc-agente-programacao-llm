# Especificação de Frontend – CRUD de Tarefas

## 1. Visão Geral
Página única (Single Page Application) para gerenciamento de lista de tarefas.  
Sem dependência de backend real; os dados são mantidos em memória (estado local) e renderizados no DOM.  
Tecnologia: HTML, CSS e JavaScript vanilla. Nenhum framework externo permitido.

## 2. Requisitos Funcionais

### 2.1. Listagem de Tarefas
- Ao carregar a página, a lista deve estar vazia.
- Cada tarefa exibe:
  - Checkbox para marcar como concluída.
  - Texto descritivo.
  - Botão "Excluir".
- Tarefa concluída deve ter estilo riscado (`text-decoration: line-through`) e cor de texto `#888`.

### 2.2. Adicionar Tarefa
- Campo de entrada (`<input type="text">`) e botão "Adicionar".
- Ao clicar em "Adicionar" ou pressionar Enter:
  - Se o campo não estiver vazio, uma nova tarefa é inserida no topo da lista.
  - O campo é limpo após a adição.
- Se o campo estiver vazio, nada acontece.

### 2.3. Excluir Tarefa
- Ao clicar no botão "Excluir" de uma tarefa, ela é removida do DOM e da lista interna.

### 2.4. Marcar como concluída
- Ao marcar o checkbox de uma tarefa, seu estado visual muda conforme descrito.
- Ao desmarcar, o estilo riscado é removido e a cor volta ao padrão.

### 2.5. Contador de tarefas
- Deve existir um elemento que exibe o número de tarefas não concluídas no formato: "X tarefa(s) pendente(s)".
- Atualiza dinamicamente ao adicionar, excluir ou alterar estado.

## 3. Estrutura do DOM (obrigatória)
Use os seguintes `data-testid` para permitir validação automatizada.  
O agente **deve** gerar exatamente estes atributos.

| Elemento                | data-testid            | Observações                         |
|-------------------------|------------------------|-------------------------------------|
| Campo de input          | `task-input`           | `<input data-testid="task-input">`  |
| Botão "Adicionar"       | `add-task-button`      | `<button data-testid="add-task-button">Adicionar</button>` |
| Lista de tarefas (ul)   | `task-list`            | `<ul data-testid="task-list">`      |
| Item de tarefa (li)     | `task-item`            | cada `<li>` deve ter este atributo  |
| Checkbox de concluir    | `task-checkbox`        | dentro do item                      |
| Texto da tarefa         | `task-text`            | span ou label                       |
| Botão excluir           | `delete-task-button`   | dentro do item                      |
| Contador de pendentes   | `pending-count`        | `<span data-testid="pending-count">`|

Exemplo de item:
```html
<li data-testid="task-item">
  <input type="checkbox" data-testid="task-checkbox">
  <span data-testid="task-text">Comprar pão</span>
  <button data-testid="delete-task-button">Excluir</button>
</li>
