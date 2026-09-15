# Ciclos Cognitivos Restritivos em Agentes Autônomos de Desenvolvimento Web

TCC (AKCIT/UFG) — Adliz Iashinishi, Diego Ferreira de Carvalho, Henrique Messias dos Santos.

Protocolo experimental **aprovado na qualificação** (parecer de 04/08/2026): compara um ciclo cognitivo restritivo (SDD → TDD → validação automatizada de DOM) contra um fluxo livre, usando **DeepSeek V4** (modelo congelado) gerando aplicações **Ruby on Rails 8**, com oráculos independentes (RSpec + Playwright E2E + asserções de DOM + comparação visual SSIM) e análise estatística pré-registrada (Wilcoxon pareado + Hodges-Lehmann + bootstrap + correção de Holm).

A implementação real do protocolo está em [`experiment/`](experiment/). Veja [`experiment/README.md`](experiment/README.md) para rodar.
