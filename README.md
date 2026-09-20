# Ciclos Cognitivos Restritivos em Agentes Autônomos de Desenvolvimento Web

TCC (AKCIT/UFG) — Adliz Iashinishi, Diego Ferreira de Carvalho, Henrique Messias dos Santos.

Protocolo experimental **aprovado na qualificação** (parecer de 04/08/2026): compara um ciclo cognitivo restritivo (SDD → TDD → validação automatizada de DOM) contra um fluxo livre, usando **DeepSeek V4** (modelo congelado) gerando aplicações **Ruby on Rails 8**, com oráculos independentes (RSpec + Playwright E2E + asserções de DOM + comparação visual SSIM) e análise estatística pré-registrada (Wilcoxon pareado + Hodges-Lehmann + bootstrap + correção de Holm).

A implementação real do protocolo está em [`experiment/`](experiment/).

## Ver os resultados (sem rodar nada)

As 30 execuções definitivas (3 tarefas × 5 repetições × 2 condições) já rodaram — os dados estão neste repositório:

- [`experiment/results_summary.csv`](experiment/results_summary.csv) — uma linha por execução, já consolidado.
- [`experiment/analysis_output.txt`](experiment/analysis_output.txt) — a saída completa da análise estatística (H1/H2/H3, Wilcoxon, Hodges-Lehmann, Holm, modelos mistos).
- [`experiment/results/`](experiment/results/) — o log bruto de cada execução (`<execution_id>/log.jsonl`: todo prompt, chamada de ferramenta e resultado de oráculo) e o código que o agente gerou em cada uma (`<execution_id>/workspace/`).

Resumo do que deu: nenhuma das três hipóteses se confirmou na direção esperada — a condição restritiva teve desempenho pior que o baseline nos três desfechos (conformidade funcional, falhas E2E, custo de tokens), com diferença estatisticamente significativa na direção oposta à hipotetizada. O efeito ficou concentrado nas tarefas com tabela (T1, T2); a tarefa de formulário (T3) não repetiu o padrão. Detalhes e discussão completos em `experiment/analysis_output.txt` e na dissertação.

## Reproduzir os resultados

Todo o passo a passo — configurar ambiente, rodar o piloto, rodar as 30 execuções definitivas, consolidar num CSV e rodar a análise estatística — está em [`experiment/README.md`](experiment/README.md). Resumo rápido:

```bash
cd experiment
pip install -r requirements.txt
python -m playwright install chromium
docker build -f docker/rails_runner.Dockerfile -t tcc-rails-runner:latest .
cp .env.example .env   # preencher DEEPSEEK_API_KEY

python run_batch.py --provider deepseek --pilot     # piloto, obrigatório antes
python run_batch.py --provider deepseek             # as 30 definitivas

python summarize_results.py --final-only > results_summary.csv
Rscript install_packages.R
Rscript analyze_results.R
```

Revalidado em 15/09: `analyze_results.R` sobre `results_summary.csv` reproduz `analysis_output.txt` de ponta a ponta, e `summarize_results.py --final-only` reconstrói exatamente as mesmas 30 execuções a partir dos logs brutos em `results/` — o pipeline é reprodutível do log bruto até o resultado final.
