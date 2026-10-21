"""Transforma as falhas do CI em anotações do GitHub Actions.

Só roda no CI (`.github/workflows/ci.yml`), com a biblioteca padrão do
Python que já vem no runner — não é dependência do app. Existe para a falha
aparecer na página do PR, no arquivo e na linha, sem precisar abrir o log:

    python3 tool/ci_anotacoes.py formato   # depois de `dart format .`: o diff
    python3 tool/ci_anotacoes.py analise analise.txt   # `dart analyze --format=machine`
    python3 tool/ci_anotacoes.py testes testes.json    # `flutter test --file-reporter json:...`

O de testes também imprime, sempre, um resumo (`::notice`) com quantos
testes rodaram.

Sempre sai com código 0: quem reprova o passo é o comando de verdade.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent

# O GitHub mostra até 10 anotações de erro por passo; mais que isso é ruído.
MAXIMO = 10


def _escapar(texto: str) -> str:
    return texto.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def _propriedade(texto: str) -> str:
    return _escapar(texto).replace(":", "%3A").replace(",", "%2C")


def _anotar(mensagem: str, *, titulo: str, arquivo: str | None = None, linha: int | None = None,
            coluna: int | None = None) -> None:
    partes = [f"title={_propriedade(titulo)}"]
    if arquivo:
        partes.append(f"file={_propriedade(arquivo)}")
    if linha:
        partes.append(f"line={linha}")
    if coluna:
        partes.append(f"col={coluna}")
    print(f"::error {','.join(partes)}::{_escapar(mensagem[:4000])}")


def _relativo(caminho: str) -> str:
    try:
        return Path(caminho).resolve().relative_to(RAIZ).as_posix()
    except ValueError:
        return caminho


def formato() -> None:
    """Um diff por arquivo que o `dart format` mudou."""
    arquivos = subprocess.run(
        ["git", "diff", "--name-only"], cwd=RAIZ, capture_output=True, text=True, check=False
    ).stdout.split()
    for arquivo in arquivos[:MAXIMO]:
        diff = subprocess.run(
            ["git", "diff", "--unified=1", "--", arquivo], cwd=RAIZ, capture_output=True, text=True, check=False
        ).stdout
        _anotar(diff, titulo="Formatação: rode dart format", arquivo=arquivo)


def analise(saida: Path) -> None:
    """`SEVERIDADE|TIPO|CODIGO|ARQUIVO|LINHA|COLUNA|TAMANHO|MENSAGEM`."""
    linhas = [l for l in saida.read_text(encoding="utf-8", errors="replace").splitlines() if l.count("|") >= 7]
    for linha in linhas[:MAXIMO]:
        severidade, _tipo, codigo, arquivo, numero, coluna, _tamanho, mensagem = linha.split("|", 7)
        _anotar(
            mensagem.replace("\\|", "|"),
            titulo=f"{severidade.lower()}: {codigo.lower()}",
            arquivo=_relativo(arquivo),
            linha=int(numero) if numero.isdigit() else None,
            coluna=int(coluna) if coluna.isdigit() else None,
        )


def _miolo_da_excecao(saida: str) -> str:
    """O que o `flutter_test` imprime quando um teste de widget falha.

    O erro do reporter, nesses testes, é só "Test failed. See exception logs
    above." — o que falhou, o esperado e o encontrado vão antes, impressos.
    Fica o trecho do cabeçalho da exceção até a pilha.
    """
    inicio = saida.find("EXCEPTION CAUGHT")
    if inicio < 0:
        return saida.strip()[-1500:]
    trecho = saida[inicio:]
    for marca in ("When the exception was thrown", "The test description was"):
        fim = trecho.find(marca)
        if fim > 0:
            trecho = trecho[:fim]
            break
    return trecho.strip()[:2500]


def testes(relatorio: Path) -> None:
    """Os erros do reporter JSON do `flutter test`, com o nome do teste.

    Erro de compilação aparece como falha do "teste" oculto que carrega o
    arquivo (`loading ...`), e entra igual. O que o teste imprimiu antes do
    erro — o relatório da exceção, nos testes de widget — entra junto.
    """
    nomes: dict[int, str] = {}
    impressos: dict[int, list[str]] = {}
    falhas: list[tuple[str, str]] = []
    contagem = {"success": 0, "failure": 0, "error": 0, "pulados": 0}
    for linha in relatorio.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            evento = json.loads(linha)
        except json.JSONDecodeError:
            continue
        if not isinstance(evento, dict):
            continue
        if evento.get("type") == "testStart":
            teste = evento.get("test", {})
            nomes[teste.get("id")] = teste.get("name", "?")
        elif evento.get("type") == "print":
            impressos.setdefault(evento.get("testID"), []).append(str(evento.get("message", "")))
        elif evento.get("type") == "testDone" and not evento.get("hidden"):
            if evento.get("skipped"):
                contagem["pulados"] += 1
            else:
                resultado = evento.get("result")
                contagem[resultado] = contagem.get(resultado, 0) + 1
        elif evento.get("type") == "error":
            id_do_teste = evento.get("testID")
            nome = nomes.get(id_do_teste, "?")
            pilha = "\n".join(str(evento.get("stackTrace", "")).splitlines()[:12])
            impresso = _miolo_da_excecao("\n".join(impressos.get(id_do_teste, [])))
            falhas.append((nome, f"{impresso}\n\n{evento.get('error', '')}\n\n{pilha}".strip()))
    # O resumo sai sempre: sem abrir o log, dá para ver quantos testes
    # rodaram - e se um teste novo entrou na conta.
    total = sum(contagem.values())
    print(
        f"::notice title=Testes::{total} testes: {contagem['success']} passaram, "
        f"{contagem['failure'] + contagem['error']} falharam, {contagem['pulados']} pulados"
    )
    for nome, mensagem in falhas[:MAXIMO]:
        _anotar(mensagem, titulo=f"Teste: {nome}"[:200])
    if len(falhas) > MAXIMO:
        _anotar(f"{len(falhas) - MAXIMO} falha(s) a mais; ver o log.", titulo="Testes")


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 0
    comando = sys.argv[1]
    try:
        if comando == "formato":
            formato()
        elif comando == "analise":
            analise(Path(sys.argv[2]))
        elif comando == "testes":
            testes(Path(sys.argv[2]))
    except (OSError, IndexError, ValueError) as erro:
        # Anotar é ajuda; nunca derruba o passo por conta própria.
        print(f"ci_anotacoes: {erro}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
