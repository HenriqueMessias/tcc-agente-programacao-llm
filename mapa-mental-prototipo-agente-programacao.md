# Mapa Mental: Ideação do Protótipo — Agente de Apoio à Programação com LLM

**Propósito:** Apresentação ao orientador — estruturação do problema, solução proposta e arquitetura do protótipo.
**Tema:** Agente de Apoio à Programação com LLM (Prompt Engineering)
**Data:** jun/2026

---

```
AGENTE DE APOIO À PROGRAMAÇÃO COM LLM
│
├── 1. PROBLEMÁTICA CENTRAL
│   │
│   ├── Pergunta de Pesquisa
│   │   └── "Em que medida a imposição de um ciclo cognitivo
│   │       restritivo — integrando SDD, TDD e Guardrails como
│   │       mecanismos de metaprompting arquitetural — reduz a
│   │       taxa de alucinação e as regressões de código, ao
│   │       mesmo tempo em que aumenta a eficiência no consumo
│   │       de tokens, em agentes LLM aplicados a tarefas de
│   │       geração, explicação e correção de código, quando
│   │       comparado ao fluxo gerativo livre?"
│   │
│   ├── Estrutura da Pergunta
│   │   ├── VI (manipulada): Modo de operação
│   │   │   ├── Controle → fluxo gerativo livre
│   │   │   └── Experimental → ciclo cognitivo restritivo (SDD+TDD+Guardrails)
│   │   ├── VD1: Taxa de alucinação (acurácia funcional)
│   │   ├── VD2: Taxa de regressão (estabilidade de código legado)
│   │   ├── VD3: Eficiência no consumo de tokens
│   │   └── Escopo: Agentes LLM em tarefas de geração, explicação e correção de código
│   │
│   ├── Dores Observadas (agentes em fluxo livre)
│   │   ├── ALUCINAÇÃO SISTÊMICA
│   │   │   └── Funções inventadas, bibliotecas inexistentes,
│   │   │       lógica que não corresponde ao requisito real
│   │   │
│   │   ├── REGRESSÕES DE CÓDIGO
│   │   │   └── Alterações que quebram funcionalidades já
│   │   │       testadas e estáveis em outras partes do sistema
│   │   │
│   │   └── DESPERDÍCIO DE TOKENS
│   │       └── Geração desnecessária (500 linhas onde 100 bastam),
│   │           loops de correção ineficientes, features extras
│   │           não solicitadas
│   │
│   └── Causa-Raiz
│       └── Ausência de GOVERNANÇA ESTRUTURAL no ciclo de
│           decisão do agente: ele age, mas não planeja nem
│           valida antes de entregar
│
├── 2. FUNDAMENTAÇÃO TEÓRICA
│   │
│   ├── Diagnóstico de Karpathy (2025)
│   │   ├── Agentes são executores caóticos por padrão
│   │   └── 4 pilares de disciplina comportamental
│   │       ├── Think Before Coding
│   │       ├── Simplicity First
│   │       ├── Surgical Changes
│   │       └── Goal-Driven Execution
│   │
│   └── Lacuna identificada
│       └── System prompts sozinhos não bastam: é preciso
│           ENFORCEMENT programático em tempo de execução
│
├── 3. HIPÓTESE
│   │
│   └── "Um loop cognitivo restritivo — que intercala SDD
│       (especificação contratual), TDD (validação contínua
│       contra um Test Harness) e Guardrails (bloqueio de
│       ações fora de escopo) — produz código mais correto,
│       consome menos tokens e causa menos regressões do que
│       o fluxo gerativo livre."
│
├── 4. ARQUITETURA DO PROTÓTIPO
│   │
│   ├── VISÃO MACRO: Duas Camadas
│   │   │
│   │   ├── CAMADA DE GOVERNANÇA (Paperclip)
│   │   │   ├── Barra ações não autorizadas (Guardrails)
│   │   │   ├── Aprova especificações antes da execução (SDD)
│   │   │   ├── Controla orçamento de tokens por tarefa
│   │   │   └── Rastreia todas as ações (auditabilidade)
│   │   │
│   │   └── CAMADA DE EXECUÇÃO (Hermes)
│   │       ├── Loop TDD: RED → GREEN → REFACTOR
│   │       ├── Memória persistente entre sessões
│   │       ├── Sandboxing (Docker/isolation)
│   │       └── Auto-correção autônoma até passar nos testes
│   │
│   └── FLUXO DETALHADO
│       │
│       [1] USUÁRIO submete intenção (issue/tarefa)
│            │
│            ▼
│       [2] PAPERCLIP recebe e SCOPEA
│            ├── Gera spec técnica (SDD): escopo, interfaces,
│            │   restrições, critérios de aceitação
│            ├── Usuário APROVA a spec (gate humano)
│            └── Define teto de tokens para a tarefa
│            │
│            ▼
│       [3] HERMES recebe a spec e executa
│            ├── Gera bateria de TESTES (Test Harness) ──── RED
│            ├── Gera implementação mínima ───────────────── GREEN?
│            │   │
│            │   ├── PASSOU? → REFACTOR → registra skill → [4]
│            │   │
│            │   └── FALHOU? → Lê log de erro → reescreve → GREEN?
│            │       (loop autônomo, até N tentativas ou teto de tokens)
│            │
│            ▼
│       [4] PAPERCLIP audita resultado
│            ├── Verifica: todos os testes passaram?
│            ├── Verifica: token budget respeitado?
│            ├── Verifica: alterações dentro do escopo?
│            └── Reporta ao usuário
│
├── 5. VARIÁVEIS DO EXPERIMENTO
│   │
│   ├── Variável Independente
│   │   └── MODO DE OPERAÇÃO DO AGENTE
│   │       ├── Controle: fluxo livre (prompt → resposta direta)
│   │       └── Experimental: arquitetura restritiva (SDD+TDD+Guardrails)
│   │
│   ├── Variáveis Dependentes (o que medimos)
│   │   ├── VD1: Taxa de alucinação
│   │   │   └── % de blocos de código com funções/APIs/imports
│   │   │       inexistentes ou incorretos
│   │   │
│   │   ├── VD2: Taxa de regressão
│   │   │   └── % de tarefas concluídas onde testes preexistentes
│   │   │       da suíte quebram após a alteração
│   │   │
│   │   ├── VD3: Eficiência de tokens
│   │   │   └── Tokens consumidos / tarefa concluída com sucesso
│   │   │
│   │   └── VD4: Taxa de acerto na 1ª iteração
│   │       └── % de tarefas que passam no Test Harness sem
│   │           necessidade de loop de correção
│   │
│   └── Variáveis de Controle
│       ├── Modelo LLM base (fixo: ex. Claude Opus 4, GPT-4o)
│       ├── Conjunto de tarefas padronizado (benchmark fixo)
│       └── Temperatura e parâmetros de inferência constantes
│
├── 6. MÉTODO
│   │
│   ├── Benchmark de Tarefas
│   │   ├── 20-30 issues reais de repositórios open-source
│   │   ├── Cobertura balanceada:
│   │   │   ├── Correção de bugs
│   │   │   ├── Adição de features
│   │   │   └── Refatoração
│   │   └── Cada tarefa possui suíte de testes preexistente
│   │       (baseline de correção)
│   │
│   ├── Procedimento (por tarefa)
│   │   ├── 1. Submeter a tarefa ao agente no modo designado
│   │   ├── 2. Coletar o código gerado
│   │   ├── 3. Executar suíte de testes + checagem de alucinação
│   │   ├── 4. Registrar tokens consumidos
│   │   └── 5. Repetir para condição controle e experimental
│   │
│   └── Análise Estatística
│       ├── Teste t pareado (controle vs. experimental)
│       ├── Tamanho de efeito (Cohen's d)
│       └── Análise qualitativa dos padrões de falha
│
├── 7. RESULTADOS ESPERADOS
│   │
│   ├── REDUÇÃO SIGNIFICATIVA em:
│   │   ├── Alucinações (VD1) ─── meta: queda > 40%
│   │   └── Regressões (VD2) ──── meta: queda > 50%
│   │
│   ├── AUMENTO SIGNIFICATIVO em:
│   │   └── Eficiência de tokens (VD3) ─── meta: redução > 30%
│   │
│   └── TRADE-OFF ESPERADO:
│       └── A 1ª iteração pode ser mais lenta (custo do SDD),
│           mas o ciclo total converge com MENOS iterações
│           e MAIOR qualidade final
│
└── 8. CONTRIBUIÇÃO ESPERADA
    │
    ├── TEÓRICA
    │   ├── Framework que traduz premissas comportamentais
    │   │   (Karpathy) em mecanismos de engenharia verificáveis
    │   └── Evidência empírica sobre eficácia de metaprompting
    │       arquitetural como estratégia de contenção
    │
    └── PRÁTICA
        ├── Protótipo open-source: Paperclip + Hermes + Harness
        ├── Reprodutível e extensível a outros domínios
        └── Métricas e benchmark reutilizáveis pela comunidade
```

---

## Notas para a Apresentação ao Orientador

### Gancho de Abertura (30 seg)
> "Hoje, agentes de IA como Claude Code e Cursor já escrevem código. O problema é que eles também **inventam funções que não existem, quebram código que já funcionava e gastam tokens como se fossem infinitos**. Minha proposta é simples: em vez de deixar o agente agir livremente, eu o coloco dentro de uma **gaiola cognitiva** — um loop fechado onde ele só age depois de especificar, só entrega depois de testar, e é bloqueado se tentar sair do escopo."

### Três Slides Mentais

| Slide | Conteúdo |
|---|---|
| **1. Dor** | Alucinação, regressão, desperdício → causa-raiz: falta de governança estrutural |
| **2. Solução** | SDD (contrato) + TDD (prova) + Guardrails (cerca) → loop cognitivo restritivo |
| **3. Evidência** | Experimento controlado (com vs. sem arquitetura), 4 VDs, benchmark de 20-30 tarefas |

### Possíveis Perguntas do Orientador (e respostas preparadas)

| Pergunta | Resposta |
|---|---|
| *"Isso não é só um prompt mais longo?"* | Não. O SDD é um artefato estrutural aprovado pelo humano; o TDD é um loop de execução com barreira; os Guardrails atuam no runtime, não no texto do prompt. É engenharia, não apenas prompting. |
| *"Por que Paperclip e Hermes e não LangChain/AutoGPT?"* | Paperclip oferece governança (budget, aprovações, auditoria) que AutoGPT não tem. Hermes oferece memória persistente e sandboxing real. São frameworks com as primitivas certas para o experimento. |
| *"Como você mede alucinação objetivamente?"* | Varredura estática do código gerado: imports resolvíveis, funções que existem nas versões especificadas das bibliotecas, assinaturas que batem com a documentação. Complementado pela taxa de falha no Test Harness. |
| *"Qual o N necessário?"* | 20-30 tarefas balanceadas é suficiente para um teste t pareado detectar tamanho de efeito médio-grande (d ≥ 0.5) com α = 0.05 e poder ≥ 0.8. |

### Conexão com os outros artefatos do TCC

- [[karpathy-agentes-disciplina-ia]] — o diagnóstico que motiva o trabalho
- [[arquitetura-cognitiva-restritiva-sdd-tdd-guardrails]] — o detalhamento completo da arquitetura

---

> **Status:** Rascunho para discussão com orientador. Ajustar escopo, variáveis e método conforme feedback.
