# Arquitetura Cognitiva Restritiva: A Integração de SDD, TDD e Guardrails na Orquestração de Agentes Autônomos

**Contexto:** Trabalho de Conclusão de Curso — Pós-graduação em Processamento de Linguagem Natural (UFG / AKCIT)
**Linha de pesquisa:** Agentes Autônomos, Engenharia de Software para IA, Orquestração de LLMs

---

## Resumo (Abstract)

**Contexto:** A transição de Modelos de Linguagem Grande (LLMs) gerativos para agentes autônomos introduziu novos desafios na engenharia de software, caracterizados por execuções caóticas, alto custo computacional e alucinações sistêmicas. Embora premissas comportamentais restritivas (como "pense antes de codificar" e "execução orientada a metas") ofereçam mitigações teóricas, a sua aplicação prática carece de rigor de engenharia.

**Problema:** A ausência de governança e validação de estado em fluxos de trabalho agênticos resulta em degradação de performance e quebras silenciosas em pipelines complexos de dados e código.

**Objetivo:** Este trabalho propõe e avalia uma arquitetura de orquestração autônoma que integra o Desenvolvimento Orientado a Especificações (SDD) e o Desenvolvimento Orientado a Testes (TDD) no núcleo cognitivo do agente, encapsulado por Guardrails dinâmicos e validado por um Test Harness.

**Metodologia:** O estudo avaliará experimentalmente a substituição de execuções gerativas de fluxo livre por um loop fechado de autoavaliação operado por orquestradores open-source (como Paperclip e Hermes). O agente é forçado a gerar especificações (SDD) antes de atuar, enquanto um Test Harness automatizado atua como critério de sucesso (TDD), barrando modificações destrutivas e desperdícios de tokens.

**Resultados Esperados:** Espera-se provar empiricamente que a imposição de restrições por meio de SDD, TDD e Guardrails reduz a dívida técnica, maximiza a previsibilidade das alterações (modificações cirúrgicas) e torna os agentes de IA ferramentas de engenharia altamente confiáveis e auditáveis.

---

## 1. Fundamentação Teórica

### 1.1 O Problema dos Agentes Caóticos

Agentes de IA autônomos baseados em LLMs, quando operam sem restrições estruturais, manifestam quatro patologias centrais:

| Patologia | Manifestação | Custo |
|---|---|---|
| Ação impulsiva | Geração de código sem validação prévia de requisitos | Retrabalho, caminhos incorretos |
| Complexidade desnecessária | Invenção de features não solicitadas, over-engineering | Desperdício de tokens, código inchado |
| Efeitos colaterais | Alterações que quebram funcionalidades não relacionadas | Regressões, instabilidade sistêmica |
| Trabalhar por trabalhar | Foco em produzir output, não em atingir metas verificáveis | Baixa qualidade, falsa sensação de conclusão |

Fonte base: Andrej Karpathy, análise do comportamento de agentes como Claude Code (2025). Ver [[karpathy-agentes-disciplina-ia]].

### 1.2 Premissas Comportamentais Restritivas

A literatura emergente e a prática da comunidade (ex.: repositório CLAUDE.md com +130k estrelas no GitHub) apontam quatro pilares de mitigação:

1. **Think Before Coding** — validar antes de executar
2. **Simplicity First** — não adicionar nada além do solicitado
3. **Surgical Changes** — modificar apenas a área designada
4. **Goal-Driven Execution** — operar orientado a metas verificáveis

Entretanto, essas premissas, quando implementadas apenas como *system prompts*, carecem de **mecanismos de enforcement em tempo de execução**. É nessa lacuna que este trabalho se insere.

---

## 2. Arquitetura Proposta: O Loop Cognitivo Restritivo

A arquitetura integra quatro componentes que se reforçam mutuamente, formando um **ciclo fechado de governança**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    PAPERCLIP (Plano de Controle)                  │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │   SDD       │  │  Guardrails  │  │  Budget & Audit        │  │
│  │ (Contract)  │  │  (Security)  │  │  (Token Tracking)      │  │
│  └──────┬──────┘  └──────┬───────┘  └───────────┬────────────┘  │
│         │                │                      │                │
│         ▼                ▼                      ▼                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                  HERMES (Executor Autônomo)                  │ │
│  │  ┌──────────┐   ┌───────────┐   ┌──────────────────────┐   │ │
│  │  │ TDD Loop │──▶│ Generate  │──▶│ Test Harness         │   │ │
│  │  │ (Red)    │   │ (Green)   │   │ (Refactor/Validate)  │   │ │
│  │  └──────────┘   └───────────┘   └──────────────────────┘   │ │
│  │       ▲                                            │        │ │
│  │       └────────────── FAIL ────────────────────────┘        │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 2.1 SDD (Specification-Driven Development) → Think Before Coding + Simplicity First

**Mecanismo:** Antes que a IA escreva qualquer código ou inicie um pipeline, o fluxo a obriga a gerar um **documento de especificação técnica**. Esse documento age como um contrato vinculante.

**No TCC:** A IA não atua sem a aprovação desse contrato. O SDD impede nativamente:
- A adição de features não solicitadas (**Simplicity First**)
- A execução sem planejamento prévio (**Think Before Coding**)

**Artefato:** Documento de especificação contendo escopo delimitado, interfaces esperadas, restrições explícitas e critérios de aceitação.

### 2.2 TDD (Test-Driven Development) + Test Harness → Goal-Driven Execution

**Mecanismo:** O TDD aplicado à IA inverte a responsabilidade tradicional. O agente deve, primeiramente, gerar (ou receber) os testes que compõem o **Test Harness**. A partir daí, ele escreve o código e o executa contra o Harness.

**Ciclo de auto-revisão (loop fechado):**
1. **RED:** O Harness define o critério de falha/sucesso
2. **GREEN:** O agente gera a implementação mínima para passar
3. **REFACTOR/VALIDATE:** O Harness reexecuta; se falhar, o agente lê o erro, analisa o log e reitera a solução de forma autônoma

**No TCC:** Materialização perfeita do **Goal-Driven Execution**: o agente não entrega o primeiro resultado; ele entra em um ciclo contínuo de auto-correção até o sinal verde, sem intervenção humana. [Karpathy, 12:23]

### 2.3 Guardrails → Surgical Changes

**Mecanismo:** Limitadores semânticos e programáticos de tempo de execução que operam na camada de **routing**, antes mesmo do consumo de processamento.

**Exemplos de regras:**
- Bloqueio de operações de escrita fora do diretório autorizado
- Proibição de comandos destrutivos (`DROP TABLE`, `rm -rf`, `DELETE FROM`)
- Validação semântica do prompt: se a intenção inferida extrapola o escopo, a ação é barrada
- Isolamento por sandbox (containers Docker, namespaces)

**No TCC:** Mecanismo de segurança que garante as **mudanças cirúrgicas**, isolando o ecossistema e protegendo código legado.

---

## 3. Orquestradores Open-Source: Hermes e Paperclip

A escolha de frameworks open-source consolidados eleva o TCC a um **padrão industrial de produção**, em vez de depender de scripts locais ad hoc.

### 3.1 Hermes Agent (Nous Research) — O Executor Autônomo

**Papel na arquitetura:** Motor cognitivo responsável pela execução do loop TDD/SDD.

**Características relevantes:**
- **Framework agnóstico** com loop de aprendizado contínuo nativo
- **Memória persistente entre sessões:** o agente aprende e corrige seus próprios erros criando *skills* que não esquece
- **Sub-agentes paralelos:** capacidade de isolar processos, permitindo que diferentes partes do pipeline rodem em sandboxes independentes
- **Sandboxing real:** suporte a Docker, Modal e outros mecanismos de contenção
- **Aprendizado por reforço no nível do agente:** o Hermes registra falhas passadas e ajusta seu comportamento futuro

**No TCC:** O Hermes implementa o loop de TDD — ele gera código, submete ao Test Harness, lê os erros e reescreve até passar.

### 3.2 Paperclip — O Plano de Controle / Governança

**Papel na arquitetura:** Camada de governança corporativa que atua como conselho de controle.

**Características relevantes:**
- **Organograma de agentes:** gerencia quais agentes estão ativos, com quais permissões
- **Alinhamento de metas:** garante que cada tarefa delegada esteja em conformidade com o objetivo macro
- **Controle de orçamento de tokens:** evita desperdício computacional, impondo limites por tarefa
- **Aprovações estritas:** implementa o fluxo de aprovação das especificações (SDD) antes da execução
- **Auditabilidade:** rastreia cada ferramenta chamada, cada prompt emitido e cada alteração realizada

**No TCC:** O Paperclip representa os macro-Guardrails e o fluxo de aprovação SDD. Ele orquestra tickets estruturados e garante prestação de contas.

### 3.3 Complementaridade entre Hermes e Paperclip

| Camada | Ferramenta | Função |
|---|---|---|
| **Governança** | Paperclip | Atribuir tarefas, aprovar specs, impor limites de tokens, auditar ações |
| **Execução** | Hermes | Loop TDD, geração de código, auto-correção, sandboxing, memória persistente |

---

## 4. Análise de Congruência

A integração SDD—TDD—Guardrails—Harness **não é uma metáfora**: é a tradução direta dos quatro pilares comportamentais para uma arquitetura de engenharia verificável.

| Pilar Comportamental (Karpathy) | Mecanismo de Engenharia | Implementação |
|---|---|---|
| Think Before Coding | SDD — contrato de especificação | Paperclip aprova spec antes de liberar execução |
| Simplicity First | SDD — escopo vinculante | Contrato impede features não especificadas |
| Goal-Driven Execution | TDD + Test Harness | Hermes itera até passar nos testes; loop RED-GREEN-REFACTOR |
| Surgical Changes | Guardrails + Sandbox | Paperclip impõe limites de escopo; Hermes roda em sandbox |

---

## 5. Metodologia Experimental (Esboço)

### 5.1 Perguntas de Pesquisa

1. **RQ1:** A imposição de SDD reduz o número de features não solicitadas geradas por agentes autônomos?
2. **RQ2:** O loop TDD com Test Harness aumenta a taxa de sucesso na primeira execução comparado ao fluxo livre?
3. **RQ3:** Guardrails em camada de routing reduzem efeitos colaterais (regressões) em bases de código legado?
4. **RQ4:** Qual o impacto combinado da arquitetura no consumo total de tokens por tarefa concluída com sucesso?

### 5.2 Design Experimental

- **Sujeito:** Agente autônomo (LLM + ferramentas)
- **Condição controle:** Execução de fluxo livre (agente recebe tarefa e age sem restrições)
- **Condição experimental:** Execução mediada pela arquitetura proposta (Paperclip + Hermes + SDD + TDD + Guardrails)
- **Tarefas:** Conjunto padronizado de issues de engenharia de software (correção de bugs, adição de features, refatoração) extraídas de repositórios open-source
- **Métricas:**
  - Taxa de conclusão correta (passa nos testes)
  - Tokens consumidos por tarefa
  - Número de iterações até convergência
  - Número de regressões introduzidas
  - Features extras não solicitadas geradas

### 5.3 Ameaças à Validade

- Viés do LLM base: diferentes modelos podem responder diferentemente às restrições
- Complexidade das tarefas: é necessário um benchmark calibrado
- Custo computacional: experimentos com LLMs são intensivos em recursos

---

## 6. Resultados Esperados

Espera-se provar empiricamente que a imposição de restrições por meio de SDD, TDD e Guardrails:

1. **Reduz a dívida técnica** — menos código desnecessário, menos retrabalho
2. **Maximiza a previsibilidade das alterações** — modificações cirúrgicas, sem efeitos colaterais
3. **Torna os agentes de IA ferramentas de engenharia confiáveis e auditáveis** — cada ação é rastreável, cada decisão é justificada por uma especificação aprovada

---

## 7. Relevância para PLN e Agentes Autônomos

| Eixo de PLN | Contribuição do Trabalho |
|---|---|
| **Agentic AI** | Propõe arquitetura de orquestração com loop fechado de auto-correção |
| **Constitutional AI / Guardrails** | Implementa restrições programáticas (não apenas textuais) no comportamento do agente |
| **Prompt Engineering Estruturado** | SDD como forma avançada de *constrained generation* |
| **Avaliação de Agentes** | Test Harness como métrica objetiva de sucesso, substituindo avaliação humana subjetiva |
| **Eficiência Computacional** | Controle de orçamento de tokens via Paperclip; redução de desperdício via TDD |
| **Memória e Aprendizado Contínuo** | Hermes com persistência de *skills* entre sessões |
| **Segurança em Agentes** | Guardrails como camada de proteção contra ações destrutivas |

---

## Referências

- Karpathy, A. Análise do comportamento de agentes de IA autônomos. Vídeo "Claude Code 10x Melhor com Estratégia de 132.000 Estrelas (Github)", Canal Maestros da IA, 2025.
- Repositório CLAUDE.md — GitHub, +130.000 estrelas. Estratégia de diretrizes centralizadas para agentes.
- Nous Research. Hermes Agent Framework — orquestrador open-source com memória persistente e sandboxing.
- Paperclip — sistema de governança para trabalho de IA: controle de orçamento, aprovações e auditabilidade.
