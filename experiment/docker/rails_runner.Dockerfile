# Ambiente de execucao por experimento: Ruby 3.3 + Rails 8 + SQLite (secao 6.6 do protocolo).
# O agente (via tool-calling) escreve codigo e roda RSpec DENTRO deste container.
# Os oraculos (Playwright E2E, asserções de DOM, comparação visual SSIM) rodam
# no orquestrador Python, no host, contra o servidor Rails exposto por este container.
FROM ruby:3.3-slim

ENV BUNDLE_PATH=/usr/local/bundle \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libsqlite3-dev \
    sqlite3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN gem install rails -v '~> 8.0' --no-document

WORKDIR /workspace

EXPOSE 3000

CMD ["sleep", "infinity"]
