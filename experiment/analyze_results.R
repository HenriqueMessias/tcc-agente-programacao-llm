#!/usr/bin/env Rscript
# Analise estatistica confirmatoria (secao 6.9) + tratamento de falhas
# (secao 6.8) + definicao de eficiencia (secao 6.2) do protocolo aprovado na
# qualificacao. Texto das secoes reproduzido abaixo (colado pelo autor a
# partir do documento aprovado em 04/08/2026 e do texto de resultados
# esperados) para que qualquer ajuste futuro possa ser conferido contra a
# redacao literal, nao contra um resumo.
#
# ---------------------------------------------------------------------
# 6.9 Analise estatistica pre-registrada
# O plano de analise e fixado antes da coleta. A analise confirmatoria
# utiliza os 15 pares agregados (3 tarefas x 5 repeticoes), com estrutura
# hierarquica por tarefa. Para H1 (proporcao mediana de criterios atendidos
# por execucao): teste de Wilcoxon pareado sobre os 15 pares, com estimador
# de Hodges-Lehmann e IC de 95% por bootstrap (10.000 reamostragens), e
# modelo misto binomial como analise secundaria (criterio atendido em
# funcao da condicao, com efeito aleatorio de tarefa e de execucao). Para H2
# (falhas E2E por execucao): Wilcoxon pareado sobre os 15 pares, com modelo
# de Poisson ou binomial negativa como analise secundaria. Para H3
# (eficiencia do par, definida na secao 3): Wilcoxon pareado sobre os 15
# pares, com modelo misto log-normal como analise secundaria; pares com
# zero execucoes aprovadas sao excluidos de H3, reportados separadamente e
# cobertos por analise de sensibilidade (secao 6.8). A analise por tarefa e
# exclusivamente exploratoria: apenas estimativas de efeito e IC de 95% por
# tarefa, sem teste de hipotese. Todas as comparacoes reportam estimativa
# de efeito, intervalo de confianca de 95% e a distribuicao dos dados --
# nao apenas p-valor --, com alfa = 0,05 unilateral e correcao de Holm para
# as tres hipoteses no nivel agregado; o tamanho de efeito e expresso por
# Cliff's delta ou r rank-biserial.
#
# 6.8 Tratamento de falhas e dados ausentes
# (i) timeout, estouro de orcamento, estado final reprovado ou ausencia de
# entrega caracterizam execucao malsucedida/interrompida por falha do
# agente -- para H1 e H2, os criterios nao verificados contam como nao
# atendidos, e os tokens consumidos ate a interrupcao sao contabilizados no
# numerador de H3; (ii) execucoes malsucedidas/interrompidas sao reportadas
# separadamente e entram na analise de sensibilidade; (iii) falha de
# infraestrutura nao e atribuida ao agente e implica nova execucao com a
# mesma seed; (iv) o criterio que distingue as duas classes e fixado antes
# da coleta e aplicado pelo orquestrador, sem intervencao manual.
#
# Resultados esperados (framing pre-registrado, 3 classes admitidas):
# 1) O protocolo integrado apresenta maior proporcao de criterios atendidos
#    e menos falhas E2E (evidencia a favor de H1/H2); DOM, visual e tempo
#    sao reportados descritivamente, sem teste de hipotese.
# 2) Pode nao haver diferenca relevante entre as condicoes -- informativo
#    para o debate sobre guardrails (Zhang et al., 2026).
# 3) A condicao restritiva pode apresentar piora em algum indicador (ex.:
#    mais ciclos de correcao sem ganho proporcional de qualidade).
# Qualidade e custo sao reportados separadamente (nao redundantes): e
# plausivel que o protocolo reduza falhas mas consuma mais tokens por
# execucao aprovada, ou o inverso (Bai et al., 2026: mais tokens nao
# implica, por si so, maior qualidade). A eficiencia (secao 6.2) e definida
# como CUSTO DE TOKENS POR EXECUCAO APROVADA -- por isso, dentro de cada
# par (task, repetition), os tokens de CADA condicao sao divididos pelo
# numero de execucoes aprovadas NAQUELE PAR (1 ou 2; pares com 0 aprovadas
# sao excluidos, por nao haver "execucao aprovada" para servir de
# denominador -- ver 6.8/6.9).
# ---------------------------------------------------------------------
#
# Direcao unilateral de cada hipotese (conforme o proposito do TCC: o ciclo
# restritivo deve REDUZIR inconsistencias e consumo de tokens frente ao
# baseline):
#   H1 (conformidade / acceptance_criteria_ratio): espera-se restricted > baseline
#   H2 (falhas E2E):                                espera-se restricted < baseline
#   H3 (tokens por execucao aprovada, secao 6.2):    espera-se restricted < baseline
#
# Uso:
#   Rscript analyze_results.R [caminho/para/results_summary.csv]

args <- commandArgs(trailingOnly = TRUE)
csv_path <- if (length(args) >= 1) args[[1]] else "results_summary.csv"
if (!file.exists(csv_path)) {
  stop(sprintf("Arquivo nao encontrado: %s (rode summarize_results.py primeiro)", csv_path))
}

suppressPackageStartupMessages({
  ok_lme4 <- requireNamespace("lme4", quietly = TRUE)
  ok_lmerTest <- requireNamespace("lmerTest", quietly = TRUE)
})
if (!ok_lme4) stop("Pacote 'lme4' nao encontrado. Rode: Rscript install_packages.R")
if (ok_lmerTest) {
  library(lmerTest)  # mascara lme4::lmer(); summary() passa a incluir Pr(>|t|) via Satterthwaite -- usado so no modelo H3 (log-normal); H1/H2 usam glmer(), nao afetado
} else {
  library(lme4)
  message("Aviso: pacote 'lmerTest' nao encontrado -- summary(m3) para H3 nao tera coluna de p-valor. Rode: install.packages('lmerTest')")
}

set.seed(42)
N_BOOT <- 10000
ALPHA <- 0.05 # unilateral, por 6.9

df <- read.csv(csv_path, stringsAsFactors = FALSE)

is_malsucedida <- function(status) grepl("^malsucedida", status)
is_infra_error <- function(status) grepl("^erro_infraestrutura", status)

if (any(is_infra_error(df$status))) {
  bad <- df$execution_id[is_infra_error(df$status)]
  stop(sprintf(
    "results_summary.csv contem execucoes com erro de infraestrutura -- por 6.8-iii, nao sao atribuidas ao agente e devem ser re-rodadas com a mesma seed antes da analise: %s",
    paste(bad, collapse = ", ")
  ))
}

cat(sprintf("Carregadas %d execucoes de %s\n", nrow(df), csv_path))
cat(sprintf("  concluida=%d  malsucedida=%d\n\n", sum(df$status == "concluida"), sum(is_malsucedida(df$status))))

## ---- 6.8-i: imputacao para H1/H2 em execucoes malsucedidas ----
## "os criterios nao verificados contam como nao atendidos" ->
##   H1: acceptance_criteria_ratio = 0
##   H2: e2e_failures = total de verificacoes E2E da tarefa

task_totals <- aggregate(
  cbind(e2e_total, acceptance_criteria_total) ~ task,
  data = df[df$status == "concluida", ], FUN = function(x) x[1]
)

impute_h1 <- function(row) if (row["status"] == "concluida") as.numeric(row["acceptance_criteria_ratio"]) else 0.0
impute_h2 <- function(row) {
  if (row["status"] == "concluida") return(as.numeric(row["e2e_failures"]))
  tot <- task_totals$e2e_total[task_totals$task == row["task"]]
  if (length(tot) == 0) return(NA_real_)
  as.numeric(tot)
}

df$h1_value <- apply(df, 1, impute_h1)
df$h2_value <- apply(df, 1, impute_h2)
df$tokens_raw <- df$total_input_tokens + df$total_output_tokens # numerador de H3 (6.8-i: inclui o consumido ate a interrupcao)
df$aprovada <- as.integer(df$status == "concluida")

## ---- monta pares (task, repetition): restricted vs baseline ----

build_pairs <- function(data, value_col) {
  wide <- reshape(
    data[, c("task", "repetition", "mode", value_col)],
    idvar = c("task", "repetition"), timevar = "mode", direction = "wide"
  )
  rcol <- paste0(value_col, ".restricted"); bcol <- paste0(value_col, ".baseline")
  wide <- wide[!is.na(wide[[rcol]]) & !is.na(wide[[bcol]]), ]
  list(task = wide$task, repetition = wide$repetition, restricted = wide[[rcol]], baseline = wide[[bcol]])
}

## ---- H3 (secao 6.2): eficiencia = tokens por execucao aprovada, dentro do PAR ----
## aprovadas_no_par in {0,1,2}; par com 0 e excluido (nao ha denominador).
## Para pares com 1 ou 2 aprovadas, os tokens de CADA condicao sao
## divididos pelo mesmo denominador (numero de aprovadas NAQUELE par) --
## nao pelo proprio status da execucao -- refletindo "custo por entrega
## aprovada gerada nessa repeticao", nao um custo individual por execucao.

pares_tokens <- reshape(
  df[, c("task", "repetition", "mode", "tokens_raw", "aprovada")],
  idvar = c("task", "repetition"), timevar = "mode", direction = "wide"
)
pares_tokens$aprovadas_no_par <- pares_tokens$aprovada.restricted + pares_tokens$aprovada.baseline
pares_zero_aprovadas <- pares_tokens[pares_tokens$aprovadas_no_par == 0, c("task", "repetition")]
pares_tokens_validos <- pares_tokens[pares_tokens$aprovadas_no_par > 0, ]
pares_tokens_validos$h3_restricted <- pares_tokens_validos$tokens_raw.restricted / pares_tokens_validos$aprovadas_no_par
pares_tokens_validos$h3_baseline <- pares_tokens_validos$tokens_raw.baseline / pares_tokens_validos$aprovadas_no_par

p3 <- list(
  task = pares_tokens_validos$task, repetition = pares_tokens_validos$repetition,
  restricted = pares_tokens_validos$h3_restricted, baseline = pares_tokens_validos$h3_baseline
)

## ---- effect sizes (Cliff's delta / r rank-biserial, por 6.9) ----

rank_biserial_paired <- function(x, y) {
  d <- x - y; d <- d[d != 0]
  if (length(d) == 0) return(NA_real_)
  r <- rank(abs(d)); w_pos <- sum(r[d > 0]); w_neg <- sum(r[d < 0])
  (w_pos - w_neg) / (w_pos + w_neg)
}
cliffs_delta <- function(x, y) mean(outer(x, y, FUN = function(a, b) sign(a - b)))

## ---- estimador de Hodges-Lehmann (mediana das medias de Walsh) ----
hodges_lehmann <- function(d) {
  walsh <- outer(d, d, "+") / 2
  median(walsh[upper.tri(walsh, diag = TRUE)])
}

## ---- IC bootstrap (percentil, 10.000 reamostragens) do HL -- metodo
## PRIMARIO de IC exigido pela secao 6.9.
bootstrap_hl_ci <- function(diffs, n_boot = N_BOOT, probs = c(0.025, 0.975)) {
  n <- length(diffs)
  boot_hl <- vapply(seq_len(n_boot), function(i) hodges_lehmann(sample(diffs, n, replace = TRUE)), numeric(1))
  quantile(boot_hl, probs = probs, names = FALSE)
}

fmt <- function(x, digits = 4) formatC(x, format = "f", digits = digits)
five_num <- function(x) sprintf("min=%s Q1=%s mediana=%s Q3=%s max=%s",
                                 fmt(min(x)), fmt(quantile(x, .25)), fmt(median(x)), fmt(quantile(x, .75)), fmt(max(x)))

## ---- teste primario por hipotese: Wilcoxon pareado UNILATERAL ----

run_hypothesis <- function(label, restricted, baseline, alternative) {
  n <- length(restricted)
  diffs <- restricted - baseline
  wt <- suppressWarnings(wilcox.test(restricted, baseline, paired = TRUE, alternative = alternative, correct = TRUE))
  hl <- hodges_lehmann(diffs)
  boot_ci <- bootstrap_hl_ci(diffs)
  rb <- rank_biserial_paired(restricted, baseline)
  cd <- cliffs_delta(restricted, baseline)
  list(label = label, n = n, alternative = alternative,
       dist_restricted = five_num(restricted), dist_baseline = five_num(baseline),
       hodges_lehmann = hl, boot_ci_low = boot_ci[1], boot_ci_high = boot_ci[2],
       p_value_onesided = wt$p.value, rank_biserial = rb, cliffs_delta = cd)
}

print_hypothesis <- function(h) {
  dir_txt <- switch(h$alternative, greater = "H_alt: restricted > baseline", less = "H_alt: restricted < baseline", "bicaudal")
  cat(sprintf("\n--- %s (n=%d pares, %s, alfa=%.2f unilateral) ---\n", h$label, h$n, dir_txt, ALPHA))
  cat(sprintf("  Distribuicao restricted: %s\n", h$dist_restricted))
  cat(sprintf("  Distribuicao baseline:   %s\n", h$dist_baseline))
  cat(sprintf("  Estimador de Hodges-Lehmann (pseudomediana da diferenca restricted-baseline) = %s\n", fmt(h$hodges_lehmann)))
  cat(sprintf("  IC 95%% bootstrap (percentil, %d reamostragens) = [%s, %s]\n", N_BOOT, fmt(h$boot_ci_low), fmt(h$boot_ci_high)))
  cat(sprintf("  p-valor (Wilcoxon signed-rank pareado, unilateral, bruto) = %s\n", fmt(h$p_value_onesided, 6)))
  cat(sprintf("  Correlacao rank-biserial pareada = %s\n", fmt(h$rank_biserial)))
  cat(sprintf("  Cliff's delta (amostras tratadas como independentes) = %s\n", fmt(h$cliffs_delta)))
}

cat("==================== ANALISE CONFIRMATORIA (secao 6.9) ====================\n")

p1 <- build_pairs(df, "h1_value")
h1 <- run_hypothesis("H1 - Conformidade funcional (acceptance_criteria_ratio)", p1$restricted, p1$baseline, alternative = "greater")

p2 <- build_pairs(df, "h2_value")
h2 <- run_hypothesis("H2 - Falhas de integracao E2E (e2e_failures)", p2$restricted, p2$baseline, alternative = "less")

h3 <- run_hypothesis("H3 - Eficiencia: tokens por execucao aprovada do par (secao 6.2)", p3$restricted, p3$baseline, alternative = "less")

print_hypothesis(h1); print_hypothesis(h2); print_hypothesis(h3)

if (nrow(pares_zero_aprovadas) > 0) {
  cat(sprintf("\n[H3] %d par(es) excluido(s) por zero execucoes aprovadas (6.9/6.8-ii):\n", nrow(pares_zero_aprovadas)))
  print(pares_zero_aprovadas)
} else {
  cat("\n[H3] Nenhum par excluido -- todos os 15 pares tem pelo menos 1 execucao aprovada.\n")
}

## ---- correcao de Holm entre as 3 hipoteses (nivel agregado, 6.9) ----

raw_p <- c(H1 = h1$p_value_onesided, H2 = h2$p_value_onesided, H3 = h3$p_value_onesided)
holm_p <- p.adjust(raw_p, method = "holm")

cat("\n--- Correcao de Holm (familia de 3 hipoteses, alfa=0,05 unilateral) ---\n")
for (name in names(raw_p)) {
  sig <- if (holm_p[name] < ALPHA) "SIGNIFICATIVO" else "nao significativo"
  cat(sprintf("  %s: p bruto = %s -> p ajustado (Holm) = %s  [%s]\n", name, fmt(raw_p[name], 6), fmt(holm_p[name], 6), sig))
}

## =====================================================================
## Classificacao automatica nas 3 classes de resultado admitidas
## (framing pre-registrado -- nenhuma das 3 classes e "falha do estudo")
## =====================================================================

## O teste primario e unilateral (so consegue rejeitar a favor da direcao
## esperada; p unilateral proximo de 1 NAO significa "sem diferenca", pode
## esconder um efeito forte na direcao oposta -- foi o caso de H2 nesta
## rodada). Por isso a classificacao nas 3 classes narrativas usa um teste
## BICAUDAL auxiliar, calculado so para esse fim -- nao substitui nem altera
## a inferencia confirmatoria primaria (unilateral, corrigida por Holm) acima.
classify_hypothesis <- function(restricted, baseline, rb, alternative) {
  p_two_sided <- suppressWarnings(wilcox.test(restricted, baseline, paired = TRUE, alternative = "two.sided", correct = TRUE)$p.value)
  if (p_two_sided >= ALPHA) return(list(classe = "(2) Sem diferenca relevante entre condicoes", p_two_sided = p_two_sided))
  favoravel <- (alternative == "greater" && rb > 0) || (alternative == "less" && rb < 0)
  if (favoravel) return(list(classe = "(1) Favoravel ao protocolo integrado", p_two_sided = p_two_sided))
  list(classe = "(3) Piora na condicao restritiva (diferenca na direcao oposta a esperada)", p_two_sided = p_two_sided)
}

cat("\n==================== CLASSIFICACAO DO RESULTADO (3 classes admitidas) ====================\n")
cat("(baseada em teste bicaudal auxiliar por hipotese, so para esta classificacao narrativa)\n")
for (nm in c("H1", "H2", "H3")) {
  h <- switch(nm, H1 = h1, H2 = h2, H3 = h3)
  pr <- switch(nm, H1 = p1, H2 = p2, H3 = p3)
  res <- classify_hypothesis(pr$restricted, pr$baseline, h$rank_biserial, h$alternative)
  cat(sprintf("  %s: %s  (p bicaudal=%s)\n", nm, res$classe, fmt(res$p_two_sided, 6)))
}
cat("\n  Nota: as 3 classes (favoravel / sem diferenca / piora) sao igualmente\n")
cat("  reportaveis por definicao do protocolo -- nenhuma invalida o estudo.\n")

## =====================================================================
## Analises secundarias confirmatorias (6.9)
## =====================================================================

cat("\n==================== ANALISES SECUNDARIAS (modelos mistos) ====================\n")

## H1 secundaria: binomial misto, criterio atendido ~ condicao, efeito
## aleatorio de tarefa e de execucao (execucao = efeito a nivel de
## observacao, ja que cada execucao contribui uma unica proporcao agregada).
cat("\n--- H1 secundaria: modelo misto binomial ---\n")
df_h1 <- df
df_h1$nao_atendidos <- ifelse(df_h1$status == "concluida",
                               df_h1$acceptance_criteria_total - df_h1$acceptance_criteria_passed,
                               df_h1$acceptance_criteria_total)
df_h1$atendidos <- ifelse(df_h1$status == "concluida", df_h1$acceptance_criteria_passed, 0)
df_h1$mode <- factor(df_h1$mode, levels = c("baseline", "restricted"))
df_h1$exec_id <- factor(seq_len(nrow(df_h1)))

m1 <- tryCatch(glmer(cbind(atendidos, nao_atendidos) ~ mode + (1 | task) + (1 | exec_id), data = df_h1, family = binomial), error = function(e) e)
if (inherits(m1, "error")) {
  cat("  [nao foi possivel ajustar]:", conditionMessage(m1), "-- provavel quase-separacao perfeita entre condicoes (ver H1 primaria: efeito ja e extremo, r_rb=-1).\n")
} else {
  print(summary(m1)$coefficients)
  print(confint(m1, method = "Wald")["moderestricted", , drop = FALSE])
}

## H2 secundaria: Poisson misto; binomial negativa mista se sobredisperso.
cat("\n--- H2 secundaria: modelo de contagem misto (Poisson -> binomial negativa se sobredisperso) ---\n")
df_h2 <- df
df_h2$mode <- factor(df_h2$mode, levels = c("baseline", "restricted"))
m2_pois <- tryCatch(glmer(h2_value ~ mode + (1 | task), data = df_h2, family = poisson), error = function(e) e)
if (inherits(m2_pois, "error")) {
  cat("  [erro ao ajustar Poisson misto]:", conditionMessage(m2_pois), "\n")
} else {
  rdf <- df.residual(m2_pois)
  disp_ratio <- sum(residuals(m2_pois, type = "pearson")^2) / rdf
  cat(sprintf("  Razao de dispersao (Pearson chisq / df) do modelo Poisson = %s (>~1.5 sugere sobredispersao)\n", fmt(disp_ratio)))
  if (disp_ratio > 1.5) {
    cat("  Sobredispersao detectada -> ajustando binomial negativa mista (glmer.nb)\n")
    m2 <- tryCatch(glmer.nb(h2_value ~ mode + (1 | task), data = df_h2), error = function(e) e)
    modelo_usado <- "binomial negativa"
  } else {
    m2 <- m2_pois; modelo_usado <- "Poisson"
  }
  if (inherits(m2, "error")) {
    cat("  [erro ao ajustar binomial negativa mista]:", conditionMessage(m2), "\n")
  } else {
    cat(sprintf("  Modelo final: %s\n", modelo_usado)); print(summary(m2)$coefficients)
  }
}

## H3 secundaria: log-normal misto sobre a mesma metrica de eficiencia
## (tokens por execucao aprovada do par), pares com 0 aprovadas excluidos.
cat("\n--- H3 secundaria: modelo misto log-normal (eficiencia, secao 6.2) ---\n")
df_h3_long <- data.frame(
  task = rep(pares_tokens_validos$task, 2), repetition = rep(pares_tokens_validos$repetition, 2),
  mode = c(rep("restricted", nrow(pares_tokens_validos)), rep("baseline", nrow(pares_tokens_validos))),
  eficiencia = c(pares_tokens_validos$h3_restricted, pares_tokens_validos$h3_baseline)
)
df_h3_long$mode <- factor(df_h3_long$mode, levels = c("baseline", "restricted"))
df_h3_long$log_eficiencia <- log(df_h3_long$eficiencia)

m3 <- tryCatch(lmer(log_eficiencia ~ mode + (1 | task), data = df_h3_long, REML = TRUE), error = function(e) e)
if (inherits(m3, "error")) {
  cat("  [erro ao ajustar log-normal misto]:", conditionMessage(m3), "\n")
} else {
  print(summary(m3)$coefficients)
  ci3 <- tryCatch(confint(m3, method = "Wald", parm = "moderestricted"), error = function(e) NULL)
  if (!is.null(ci3)) {
    cat("  IC 95% de Wald para mode=restricted (escala log):\n"); print(ci3)
    cat(sprintf("  Razao geometrica de eficiencia (restricted/baseline) = %s [IC 95%%: %s, %s]\n",
                fmt(exp(fixef(m3)["moderestricted"])), fmt(exp(ci3[1])), fmt(exp(ci3[2]))))
  }
}

## =====================================================================
## Analise exploratoria por tarefa (6.9: apenas efeito + IC, sem teste)
## =====================================================================

cat("\n==================== ANALISE EXPLORATORIA POR TAREFA (sem teste de hipotese) ====================\n")

explore_by_task <- function(label, pairs) {
  cat(sprintf("\n--- %s ---\n", label))
  for (task in unique(pairs$task)) {
    idx <- pairs$task == task
    r <- pairs$restricted[idx]; b <- pairs$baseline[idx]; d <- r - b
    if (length(d) < 2) { cat(sprintf("  %-18s n=%d (insuficiente para IC bootstrap)\n", task, length(d))); next }
    hl <- hodges_lehmann(d); ci <- bootstrap_hl_ci(d); rb <- rank_biserial_paired(r, b)
    cat(sprintf("  %-18s n=%d  HL=%s  IC95%%boot=[%s, %s]  r_rb=%s\n", task, length(d), fmt(hl), fmt(ci[1]), fmt(ci[2]), fmt(rb)))
  }
}
explore_by_task("H1 - Conformidade funcional, por tarefa", p1)
explore_by_task("H2 - Falhas E2E, por tarefa", p2)
explore_by_task("H3 - Eficiencia (tokens/execucao aprovada), por tarefa", p3)

## =====================================================================
## Desfechos secundarios/exploratorios DESCRITIVOS (sem teste de hipotese):
## conformidade estrutural do DOM, conformidade visual e tempo.
## =====================================================================

cat("\n==================== DESFECHOS DESCRITIVOS (DOM, visual, tempo -- sem teste) ====================\n")

describe_by_mode <- function(label, values_by_mode) {
  cat(sprintf("\n--- %s ---\n", label))
  for (m in names(values_by_mode)) {
    v <- values_by_mode[[m]]
    if (length(v) == 0 || all(is.na(v))) { cat(sprintf("  %-11s sem dados\n", m)); next }
    v <- v[!is.na(v)]
    cat(sprintf("  %-11s n=%d  %s\n", m, length(v), five_num(v)))
  }
}

conc <- df[df$status == "concluida", ]
conc$dom_ratio <- ifelse(conc$dom_assertions_total > 0, conc$dom_assertions_passed / conc$dom_assertions_total, NA)
conc$visual_ratio <- ifelse(conc$visual_captures_total > 0, conc$visual_captures_passed / conc$visual_captures_total, NA)

describe_by_mode("Conformidade estrutural do DOM (dom_assertions_passed/total, apenas execucoes concluida)",
                  split(conc$dom_ratio, conc$mode))
describe_by_mode("Conformidade visual (visual_captures_passed/total, apenas execucoes concluida)",
                  split(conc$visual_ratio, conc$mode))
describe_by_mode("Tempo de execucao em segundos (elapsed_s, todas as 30 execucoes)",
                  split(df$elapsed_s, df$mode))

## =====================================================================
## Execucoes malsucedidas reportadas separadamente (6.8-ii)
## =====================================================================

cat("\n==================== EXECUCOES MALSUCEDIDAS (reportadas separadamente, 6.8-ii) ====================\n")
mal <- df[is_malsucedida(df$status), c("execution_id", "task", "mode", "seed", "repetition", "status", "total_cost_usd", "tokens_raw")]
if (nrow(mal) == 0) {
  cat("  Nenhuma.\n")
} else {
  print(mal, row.names = FALSE)
  cat(sprintf("\n  Total: %d/%d execucoes malsucedidas (%.1f%%)\n", nrow(mal), nrow(df), 100 * nrow(mal) / nrow(df)))
  cat("  Por tarefa x condicao:\n"); print(table(mal$task, mal$mode))
}

## ---- registro de versoes de pacotes (6.9) ----
version_file <- "r_package_versions.txt"
sink(version_file)
cat("Gerado por analyze_results.R em", format(Sys.time()), "\n\n")
print(sessionInfo())
sink()
cat(sprintf("\nVersoes de pacotes registradas em %s\n", version_file))

cat("\n=================================================================\n")
