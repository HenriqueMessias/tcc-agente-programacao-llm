# Protocolo experimental — Ciclos Cognitivos Restritivos (Rails 8 + DeepSeek V4)

Implementação do protocolo aprovado na qualificação (04/08/2026).

## Configuração

```bash
cd experiment
pip install -r requirements.txt
python -m playwright install chromium
docker build -f docker/rails_runner.Dockerfile -t tcc-rails-runner:latest .
cp .env.example .env
# edite .env e preencha DEEPSEEK_API_KEY e/ou ANTHROPIC_API_KEY (nunca cole a chave no chat)
```

## Rodando uma execução

```bash
python -m orchestrator.run_execution --task t1_biblioteca --mode restricted --seed 1 --provider deepseek
python -m orchestrator.run_execution --task t1_biblioteca --mode baseline --seed 1 --provider deepseek
```

Cada execução sobe um contêiner Docker novo (Ruby 3.3 + Rails 8 + SQLite), roda o agente via tool-calling (temperatura 0,2) e grava um log estruturado em `results/<execution_id>/log.jsonl` — prompts, mensagens, chamadas de ferramenta, resultado de cada oráculo, custo por chamada.

Sobre `--provider anthropic`: o protocolo aprovado especifica DeepSeek V4 como único modelo, idêntico nas duas condições. Usar Claude via `anthropic_client.py` é um desvio por restrição de orçamento — mantém o princípio (um modelo fixo, igual em baseline e restricted), só troca qual modelo é. Isso precisa entrar na seção de método da dissertação (data, motivo, e deixar claro que dentro de uma mesma leva o provedor não varia entre baseline/restricted do mesmo par). Não misturar provedores dentro das 15 pares de uma leva confirmatória.

## Do piloto ao relatório

Antes de rodar qualquer execução definitiva, roda o piloto (T1 nas duas condições, 1 execução cada):

```bash
python run_batch.py --provider deepseek --pilot
python summarize_results.py --task t1_biblioteca
```

O piloto só passa se nenhuma das colunas `acceptance_criteria_ratio`, `dom_assertions_*`, `visual_captures_*`, `e2e_*` ficar vazia nas execuções `concluida`. Se ficar, é bug de instrumentação, não segue para as definitivas ainda. Vale também dar uma olhada em `max_input_tokens_single_call` — teve um bug de explosão de contexto (ver embaixo) que inflava isso pra dezenas de milhares; hoje deveria ficar na casa de 5-15K.

Passando no piloto, roda as 30 execuções definitivas (3 tarefas × 5 repetições × 2 condições, ordem contrabalanceada):

```bash
python run_batch.py --provider deepseek
```

Demora — cada execução vai de alguns minutos até uns 25min quando bate o timeout — então deixa rodando em background ou numa sessão que não vai fechar. Salva um resumo em `results/batch_summary_<timestamp>.json` no final, e cada execução grava seu próprio log incrementalmente (dá pra acompanhar antes de terminar tudo). Se preferir rodar tarefa por tarefa (mais seguro se travar no meio):

```bash
python run_batch.py --provider deepseek --tasks t1_biblioteca
python run_batch.py --provider deepseek --tasks t2_dashboard
python run_batch.py --provider deepseek --tasks t3_autenticacao
```

Pra depurar uma execução específica sem rodar o lote inteiro, usa o comando de execução única lá em cima. O container some no final, mas o workspace (o que o agente gerou) fica em `results/<execution_id>/workspace/` pra inspecionar. Pra ver o log inteiro, prompt por prompt:

```bash
python -c "
import json
for line in open('results/<execution_id>/log.jsonl', encoding='utf-8'):
    rec = json.loads(line)
    print(rec['event'], '-', {k: v for k, v in rec.items() if k not in ('event','ts')})
"
```

Com tudo rodado, consolida num CSV:

```bash
python summarize_results.py > results_summary.csv
```

Uma linha por execução, com as colunas que a análise da seção 6.9 precisa (H1: `acceptance_criteria_ratio`; H2: `e2e_failures`; H3: tokens/custo — a eficiência em si é calculada no script de análise). E por fim a análise estatística:

```bash
Rscript install_packages.R   # só na primeira vez, instala lme4 e lmerTest
Rscript analyze_results.R    # le results_summary.csv, imprime H1/H2/H3
```

Roda Wilcoxon pareado unilateral, Hodges-Lehmann com IC 95% por bootstrap, correção de Holm e os modelos mistos secundários. Sem `lmerTest` instalado o modelo de H3 ainda funciona (via `lme4`), só sem p-valor no summary.

## O que é cada coisa

- `orchestrator/` — o orquestrador: `state_machine.py` tem as 5 fases (SPEC→RED→GREEN→REFACTOR→DOM_VISUAL), `deepseek_client.py`/`anthropic_client.py` implementam a mesma interface (`llm_client_base.py`), `tools.py` são as ferramentas do agente, `container.py` cuida do Docker, `oracle_runner.py`/`final_evaluation.py` fazem a avaliação independente, `logging_.py` é o log estruturado.
- `tasks/<nome>/task.md` — enunciado e critérios de aceitação, congelados antes da coleta.
- `tasks/<nome>/oracle/` — os testes-oráculo: RSpec em `spec/`, Playwright em `e2e/e2e_checks.py`, `dom_assertions.yml`, imagens em `screenshots/`.
- `tasks/<nome>/reference_app/` — app de referência, só pra derivar/validar os oráculos, não entra na análise.
- `visual_diff.py` — comparação visual (SSIM sobre wireframe em baixa resolução).
- `run_batch.py` / `summarize_results.py` — rodam o lote e consolidam os logs num CSV.
- `results/` — fica de fora do git, são os logs de cada execução.

## Pendências

As 30 execuções definitivas rodaram no dia 15/09 (DeepSeek): 20 `concluida`, 10 `malsucedida` (bateram em `max_iterations`/`max_dom_visual_passes` — resultado legítimo do protocolo, não bug), custo total US$2,57. `results_summary.csv` já validado, sem métrica vazia nas concluídas. Seis execuções bateram nos bugs de infraestrutura abaixo e foram re-rodadas com a mesma seed pra não quebrar o pareamento. O script de análise em R também já está pronto. Falta só o checklist de auditoria (seção 6.8/8).

## Histórico de bugs

Guardando aqui porque foram trabalhosos de rastrear e algum dia alguém (provavelmente eu de novo) vai bater neles de novo em outro contexto.

**Explosão de contexto/custo (14/09).** O primeiro piloto de verdade (Claude, T1 restricted) gastou 4,5 milhões de tokens de entrada e US$4,73 numa execução que nem terminou — cada chamada ao modelo ia de ~2 mil pra ~80 mil tokens ao longo de ~100 chamadas porque o histórico de mensagens (saída de `bundle install`, log do RSpec, listagem de arquivos...) nunca era podado. Não é coisa do Claude especificamente, é `state_machine.py::agent_loop`, camada compartilhada por qualquer provedor. Arrumei com uma janela deslizante de no máximo 30 mensagens em `_compact_messages` (o que sai vira um resumo de uma linha), truncando a saída de `run_command` pra 2.500 caracteres, e limitando `read_file`/`list_files` também. Testei isolado (histórico simulado de 60 turnos ficou estável em 29 mensagens) e depois numa execução real — 203 chamadas, mais que as ~99 que causaram o incidente, com `max_input_tokens_single_call` estável em ~13 mil e custo de US$0,42.

**Três bugs que só apareceram no fluxo completo (14-15/09), rodando com DeepSeek de verdade:**

O `bundle exec rspec 2>&1 | tail -N` mascarava o exit code — em `sh -c` o exit code de um pipe é o do último comando (`tail`), que quase sempre dá 0, então o orquestrador achava que os testes sempre passavam. Isso travou a fase RED num loop por 150+ chamadas e ~18 minutos até eu perceber. Tirei o `| tail`, já que `run_command` trunca a saída em Python mesmo.

Depois, conflito de porta no `rails server` da avaliação final: no baseline o agente às vezes sobe seu próprio server pra testar e tenta matar com `pkill`, que não existe na imagem (slim, sem procps) — o processo órfão fica preso na porta 3000 e o server "oficial" da avaliação nunca consegue subir. Todas as checagens de DOM/E2E davam `net::ERR_EMPTY_RESPONSE` numa execução que na real tinha dado certo. `start_rails_server` agora mata qualquer processo do pidfile antigo antes de subir um novo e espera de verdade (poll via curl) em vez de um sleep fixo.

E o pior dos três: o JSON do RSpec da avaliação final vinha truncado, porque `final_evaluation.py` lia pelo stdout de `run_command` (cortado em 2.500 caracteres) — qualquer suíte um pouco maior cortava o JSON no meio e o parsing caía no fallback 0/0, zerando `acceptance_criteria_ratio`, que é a métrica de H1, a mais importante do TCC, em toda execução que na verdade tinha dado certo. Agora o RSpec escreve o resultado num arquivo dentro do workspace (que é bind-mount, então sobrevive fora do container) e `final_evaluation.py` lê direto do disco.

Os três foram achados e corrigidos na mesma sessão, cada um confirmado com reexecução real antes de ir pro próximo. Nenhum é específico do DeepSeek.

**Durante as 30 definitivas (15/09):** apareceram mais dois, ambos classificados como `erro_infraestrutura` (6 das 30 execuções precisaram ser re-rodadas por causa deles). A API do DeepSeek rejeita `"tool_calls": []` com HTTP 400 quando o array vem vazio — precisa omitir a chave inteira quando o modelo não chama nenhuma ferramenta, não mandar lista vazia (isso é específico do formato DeepSeek, Anthropic não tem essa exigência). E teve uma falha intermitente, tipo `'NoneType' object is not subscriptable` em `deepseek_client.py::chat`, em ~10% das chamadas finais do lote — não reproduz sob demanda, parece um hiccup da API. Botei retry (3 tentativas, backoff de 2s) e o traceback completo agora vai pro log pra facilitar se acontecer de novo.

Regra geral: se `acceptance_criteria_ratio` (ou qualquer outra métrica) aparecer vazia numa execução `concluida`, ou `status` começar com `erro_infraestrutura`, não entra na análise — re-roda com a mesma seed/repetition pra não quebrar o pareamento.

## Outras coisas de infra que valem saber

- O gem `json` 3.x não é compatível com Rails 8.1/Ruby 3.3 nessa imagem, quebra sessão/CSRF — por isso o prompt-base pede pra fixar `gem "json", "~> 2.9"`, vale pras duas condições.
- `RAILS_ENV` não pode ficar fixado em `development` na imagem — quebra o fallback pra `test` que o rspec-rails precisa (CSRF e host authorization só funcionam em `test`).
- No Git Bash/MSYS do Windows, chamadas manuais de `docker` precisam de `MSYS_NO_PATHCONV=1`, senão `/workspace` em `-v host:/workspace` vira um caminho Windows e quebra o bind mount sem avisar. Isso não afeta o orquestrador (usa `subprocess` direto), só depuração manual no terminal.
- `pkill`/`fuser` não existem na imagem (slim, sem procps) — usa `kill -9 $(cat tmp/pids/server.pid)`.
- E no mesmo Git Bash/MSYS, `pkill -f "run_batch.py"` não mata o processo Python de verdade — o `ps` desse ambiente não vê os argumentos da linha de comando, só o executável, então nunca dá match e o processo fica zumbi consumindo API. Pega o PID direto (`ps -ef | grep python`) e mata com `kill -9`.
