"""Lista o que a versão web precisa para abrir sem internet (US42).

Roda DEPOIS do `flutter build web`, sobre a pasta do build:

    python3 tool/lista_offline.py build/web

Escreve `arquivos_offline.json` (a versão e a lista dos arquivos) e carimba a
versão em `servico_offline.js`. O service worker (`web/servico_offline.js`)
lê a lista ao se instalar e guarda tudo de uma vez; o carimbo muda os bytes
do próprio service worker a cada build diferente, e é isso que faz o
navegador instalar o novo.

A versão é o hash do conteúdo, não a data: build igual, versão igual, e
ninguém baixa tudo de novo à toa.

Ficam de fora o que o navegador do iPhone nunca pede (o CanvasKit dos
navegadores Chromium e o skwasm, que é do build em WebAssembly) e os mapas
de depuração. Se algum navegador pedir um deles, o service worker guarda na
primeira vez que buscar.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

LISTA = "arquivos_offline.json"
SERVICE_WORKER = "servico_offline.js"
CARIMBO = "__VERSAO_OFFLINE__"

FORA = (
    SERVICE_WORKER,
    LISTA,
    "flutter_service_worker.js",
    ".last_build_id",
)


def _fica_de_fora(relativo: str) -> bool:
    if relativo in FORA:
        return True
    if relativo.endswith((".map", ".symbols")):
        return True
    if relativo.startswith("canvaskit/chromium/"):
        return True
    return relativo.startswith("canvaskit/skwasm")


def main(pasta: Path) -> None:
    arquivos: list[str] = []
    resumo = hashlib.sha256()
    for caminho in sorted(p for p in pasta.rglob("*") if p.is_file()):
        relativo = caminho.relative_to(pasta).as_posix()
        if _fica_de_fora(relativo):
            continue
        arquivos.append(relativo)
        resumo.update(relativo.encode())
        resumo.update(hashlib.sha256(caminho.read_bytes()).digest())

    versao = resumo.hexdigest()[:16]
    (pasta / LISTA).write_text(
        json.dumps({"versao": versao, "arquivos": arquivos}, indent=1),
        encoding="utf-8",
    )

    service_worker = pasta / SERVICE_WORKER
    texto = service_worker.read_text(encoding="utf-8")
    if CARIMBO not in texto:
        sys.exit(f"{service_worker} não tem o carimbo {CARIMBO}.")
    service_worker.write_text(texto.replace(CARIMBO, versao), encoding="utf-8")

    tamanho = sum((pasta / a).stat().st_size for a in arquivos)
    print(
        f"{len(arquivos)} arquivos, {tamanho / 1e6:.1f} MB, versão {versao}"
    )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Uso: python3 tool/lista_offline.py build/web")
    main(Path(sys.argv[1]))
