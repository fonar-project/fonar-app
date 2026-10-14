#!/usr/bin/env bash
# Prepara a pasta web/ para o build da versão no navegador (US42).
#
# O banco local, no navegador, é o SQLite compilado para WebAssembly
# (sqlite3.wasm) rodando num worker (drift_worker.js). Os dois não são
# versionados: vêm da release do drift que o pubspec.lock fixou, e a versão
# tem de ser a mesma — worker de uma versão com o drift de outra é a receita
# de um banco que não abre.
#
# Uso, na raiz do projeto:
#
#     bash tool/preparar_web.sh
#     flutter build web --release --base-href /fonar-app/ --no-web-resources-cdn
#     python3 tool/lista_offline.py build/web
#
# O CI faz o mesmo (ci.yml e release.yml).
set -euo pipefail

versao=$(awk '
  $0 == "  drift:" { achou = 1; next }
  achou && $1 == "version:" { gsub(/"/, "", $2); print $2; exit }
' pubspec.lock)

if [ -z "$versao" ]; then
  echo "Não achei a versão do drift no pubspec.lock." >&2
  exit 1
fi

base="https://github.com/simolus3/drift/releases/download/drift-$versao"
for arquivo in sqlite3.wasm drift_worker.js; do
  echo "Baixando $arquivo do drift $versao"
  curl -fsSL --retry 3 -o "web/$arquivo" "$base/$arquivo"
done

# Um wasm que não começa com "\0asm" é uma página de erro salva com o nome
# certo — melhor parar aqui do que publicar um banco que não abre.
if [ "$(head -c 4 web/sqlite3.wasm | od -An -tx1 | tr -d ' \n')" != "0061736d" ]; then
  echo "web/sqlite3.wasm não é WebAssembly." >&2
  exit 1
fi
