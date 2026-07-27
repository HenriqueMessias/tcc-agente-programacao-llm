# Guia do Agente – Geração de Frontend com Ciclo Restritivo

## Seu objetivo
Você deve gerar o código frontend (HTML/CSS/JS) para a especificação anexada (`sdd-*.md`) seguindo rigorosamente o ciclo:

1. **Leia e entenda a especificação SDD.**
2. **Gere os testes automatizados** baseados no SDD (caso não fornecidos, use o padrão de validação de DOM com `data-testid`).
3. **Implemente o código** que satisfaça todos os testes.
4. **Execute os testes** usando Playwright (ou ferramenta configurada).
5. **Se houver falha:**
   - Analise o log de erro.
   - Corrija **exclusivamente** o código, sem alterar a especificação.
   - Nunca remova ou modifique um `data-testid` que está no contrato.
   - Reexecute os testes.
6. **Repita até 100% de aprovação.**

## Regras restritivas (Guardrails)
- Você não pode adicionar funcionalidades não solicitadas (ex.: persistência em localStorage a menos que o SDD peça).
- Você não pode alterar a estrutura do DOM especificada (atributos `data-testid` são obrigatórios e imutáveis).
- O código deve ser autocontido (HTML único com `<style>` e `<script>` internos, salvo indicação contrária).
- Após cada mudança, **execute toda a suíte de testes** para detectar regressões.

## Exemplo de ciclo
1. SDD: "Campo de input deve ter data-testid='task-input'".  
2. Você gera teste: `expect(page.locator('[data-testid="task-input"]')).toBeVisible()`.  
3. Implementa `<input data-testid="task-input" ...>`.  
4. Teste passa → Próximo requisito.  
5. Se quebrar algo, corrija e rode todos os testes novamente.

## Como rodar os testes (para o ambiente Hermes)
- O servidor web será levantado com `npx http-server ./src -p 3000`.
- Execução dos testes: `npx playwright test`.
- Você deve interpretar o relatório para decidir os próximos passos.
