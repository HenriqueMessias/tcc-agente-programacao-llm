# Instala na biblioteca padrão do usuário (R_LIBS_USER), igual em
# Windows, macOS e Linux -- sem caminho fixo de plataforma.
userlib <- Sys.getenv("R_LIBS_USER")
if (nzchar(userlib) && !dir.exists(userlib)) {
  dir.create(userlib, recursive = TRUE, showWarnings = FALSE)
}
cat("Instalando em:", if (nzchar(userlib)) userlib else .libPaths()[1], "\n")
install.packages(c("lme4", "lmerTest"), repos = "https://cloud.r-project.org")
cat("OK\n")
