# T2 — Dashboard de métricas

Desenvolva um dashboard de vendas com indicadores agregados, tabela de dados e um gráfico, com filtro por intervalo de datas e estado vazio.

## Requisitos funcionais

- Um pedido (order) tem valor (amount), categoria (category) e data (order_date).
- O dashboard mostra, para um intervalo de datas (padrão: todos os pedidos se nenhum filtro for informado): total de vendas (soma dos valores), número de pedidos, e ticket médio.
- O dashboard mostra uma tabela com os pedidos do período (categoria e valor).
- O dashboard mostra uma representação gráfica dos valores agregados por categoria (pode ser um gráfico de barras simples feito só com HTML/CSS — não é necessário JavaScript nem bibliotecas externas).
- É possível filtrar o período via parâmetros de data na URL.
- Quando não há pedidos no período filtrado, o dashboard exibe uma mensagem de estado vazio (não um erro).

## Convenção de rotas (obrigatória, para viabilizar avaliação automatizada)

- Rota principal: `GET /dashboard`.
- Filtro de período via parâmetros de query `start_date` e `end_date` (formato `YYYY-MM-DD`), ex.: `/dashboard?start_date=2026-01-01&end_date=2026-01-31`.
- O elemento raiz da página deve ter `id="dashboard"`.
- O indicador de total de vendas deve ter `id="metric-total"`.
- O indicador de número de pedidos deve ter `id="metric-count"`.
- O indicador de ticket médio deve ter `id="metric-average"`.
- A tabela de pedidos deve ter `id="orders-table"`.
- O gráfico deve ter `id="chart"`, com um elemento filho por categoria com a classe `chart-bar`.
- O formulário de filtro deve ter `id="filter-form"`, com campos `name="start_date"` e `name="end_date"`.
- Quando não há pedidos no período, deve existir um elemento com `id="empty-state"`.

## Critérios de aceitação (congelados antes da execução)

1. Visitar `/dashboard` retorna HTTP 200.
2. O dashboard exibe o indicador de total de vendas, correto para os pedidos existentes.
3. O dashboard exibe o indicador de número de pedidos, correto para os pedidos existentes.
4. O dashboard exibe o indicador de ticket médio, correto (total ÷ número de pedidos).
5. O dashboard exibe uma tabela listando os pedidos, com categoria e valor de cada um.
6. O dashboard exibe uma representação gráfica com um elemento por categoria presente nos dados.
7. Filtrar por um intervalo de datas via `start_date`/`end_date` restringe os pedidos considerados nos indicadores e na tabela.
8. Filtrar por um intervalo sem pedidos correspondentes exibe o estado vazio, sem erro HTTP 500.
9. Os indicadores refletem corretamente apenas os pedidos dentro do intervalo filtrado (não incluem pedidos fora do intervalo).
10. A soma dos valores exibidos na tabela do período filtrado é consistente com o indicador de total exibido.
