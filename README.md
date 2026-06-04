# Agente de Apoio à Programação com LLM — Arquitetura Cognitiva Restritiva

**Trabalho de Conclusão de Curso**  
Pós-graduação em Processamento de Linguagem Natural  
Universidade Federal de Goiás (UFG) — Programa AKCIT

---

## Visão Geral

Este repositório contém os artefatos de ideação e planejamento do protótipo de um **agente de apoio à programação baseado em LLM** guiado por uma arquitetura de **metaprompting restritivo**. O trabalho investiga como a integração de SDD (Specification-Driven Development), TDD (Test-Driven Development) e Guardrails — operando em um loop cognitivo fechado — pode reduzir alucinações, regressões de código e desperdício de tokens em agentes autônomos.

### Pergunta de Pesquisa

> Em que medida a imposição de um ciclo cognitivo restritivo — integrando SDD, TDD e Guardrails como mecanismos de metaprompting arquitetural — reduz a taxa de alucinação e as regressões de código, ao mesmo tempo em que aumenta a eficiência no consumo de tokens, em agentes LLM aplicados a tarefas de geração, explicação e correção de código, quando comparado ao fluxo gerativo livre?

### Hipótese (H₁)

Um loop cognitivo restritivo — que intercala SDD (especificação contratual), TDD (validação contínua contra um Test Harness) e Guardrails (bloqueio de ações fora de escopo) — produz código mais correto, consome menos tokens e causa menos regressões do que o fluxo gerativo livre.

---

## Estrutura do Repositório

| Arquivo | Descrição |
|---|---|
| `README.md` | Este arquivo — visão geral do projeto |
| `karpathy-agentes-disciplina-ia.md` | Fichamento: diagnóstico de Andrej Karpathy sobre agentes caóticos e os 4 pilares comportamentais (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution) |
| `arquitetura-cognitiva-restritiva-sdd-tdd-guardrails.md` | Artigo-base da proposta: arquitetura cognitiva restritiva integrando SDD, TDD, Guardrails e Test Harness com orquestradores open-source (Paperclip + Hermes) |
| `mapa-mental-prototipo-agente-programacao.md` | Mapa mental textual com a estrutura completa da ideação: problemática, fundamentação, hipótese, arquitetura, variáveis, método, resultados esperados e contribuição. Inclui notas para apresentação ao orientador |
| `mapa-mental-tcc.excalidraw` | Diagrama visual do mapa mental pronto para importar no [Excalidraw](https://excalidraw.com) |
| `generate-excalidraw.js` | Script Node.js que gera o arquivo `.excalidraw` a partir da definição programática dos elementos |

---

## Arquitetura do Protótipo (Resumo)

```
┌─────────────────────────────────────────────────┐
│           PAPERCLIP (Governança)                 │
│  SDD (contrato) + Guardrails + Budget Control   │
└──────────────────┬──────────────────────────────┘
                   │ spec aprovada
                   ▼
┌─────────────────────────────────────────────────┐
│           HERMES (Execução)                      │
│  Loop TDD: RED → GREEN → REFACTOR               │
│  Test Harness + Sandbox + Auto-correção          │
└──────────────────┬──────────────────────────────┘
                   │ resultado auditado
                   ▼
              [Usuário]
```

### Congruência entre Pilares Comportamentais e Mecanismos de Engenharia

| Pilar (Karpathy, 2025) | Mecanismo | Implementação |
|---|---|---|
| Think Before Coding + Simplicity First | **SDD** — contrato de especificação | Paperclip aprova spec antes da execução |
| Goal-Driven Execution | **TDD + Test Harness** — loop RED-GREEN-REFACTOR | Hermes itera até passar nos testes |
| Surgical Changes | **Guardrails + Sandbox** — isolamento | Paperclip bloqueia ações fora de escopo |

---

## Desenho Experimental (Resumo)

- **Condição controle:** Agente LLM em fluxo gerativo livre (prompt → resposta direta)
- **Condição experimental:** Agente com arquitetura restritiva (SDD + TDD + Guardrails + Harness)
- **Benchmark:** 20–30 issues reais de repositórios open-source (bug fixes, features, refatoração)
- **Variáveis dependentes:**
  - VD1: Taxa de alucinação
  - VD2: Taxa de regressão
  - VD3: Eficiência de tokens
  - VD4: Taxa de acerto na 1ª iteração
- **Análise:** Teste t pareado, Cohen's d, análise qualitativa de padrões de falha

---

## Como Usar o Diagrama Excalidraw

1. Acesse [excalidraw.com](https://excalidraw.com)
2. Clique no menu superior esquerdo → **Open**
3. Selecione o arquivo `mapa-mental-tcc.excalidraw`
4. O diagrama será carregado com todos os 8 ramos do mapa mental, setas de conexão e legendas

Para regenerar o diagrama após alterações:
```bash
node generate-excalidraw.js
```

---

## Referências

- **Karpathy, A.** (2025). Análise do comportamento de agentes de IA autônomos. Vídeo "Claude Code 10x Melhor com Estratégia de 132.000 Estrelas (Github)", Canal Maestros da IA.
- **CLAUDE.md** — Repositório GitHub (+130.000 ★). Estratégia de diretrizes centralizadas para disciplina de agentes.
- **Nous Research.** Hermes Agent Framework — orquestrador open-source com memória persistente, sandboxing e loop de aprendizado contínuo.
- **Paperclip** — Sistema de governança para orquestração de agentes de IA: controle de orçamento, aprovações e auditabilidade.

---

## Status

🟡 **Em ideação** — Rascunho para discussão com orientador. Sujeito a ajustes de escopo, método e variáveis conforme feedback da banca.

---

> **Orientação:** UFG / AKCIT — Processamento de Linguagem Natural  
> **Autor:** [henri]  
> **Licença:** Este repositório é privado. Consulte o autor antes de compartilhar.
