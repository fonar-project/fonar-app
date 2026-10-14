"""Gera os arquivos da marca FONAR (US47): o símbolo da onda de voz que vira
ondas de sonar, os ícones e a assinatura.

    pip install cairosvg fonttools pillow
    python3 tool/gerar_marca.py /tmp/marca assets/fonts/Urbanist-ExtraBold.ttf

Escreve os SVG (os mesmos de `marca/`) e, em `png/`, os PNG de cada
tamanho e o `app_icon.ico` do Windows. Para onde cada um vai, no app e na
landing: `marca/README.md`. Só é preciso rodar de novo se o desenho mudar.
"""

import io
import struct
import sys
from pathlib import Path

import cairosvg
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from PIL import Image

SAIDA = Path(sys.argv[1])
FONTE = sys.argv[2]
SAIDA.mkdir(parents=True, exist_ok=True)

ROXO = "#40085E"
CREME = "#FFF7EB"

# O símbolo, num quadro de 64: a onda de voz (à esquerda) que vira três ondas
# de sonar. As curvas "S" já estão expandidas em "C" (mesmo desenho), porque
# o VectorDrawable do Android e o Path do Flutter não têm atalho.
ONDA = (
    "M5 32C6.5 23 10 23 11.8 32"
    "C13.6 41 16.2 38.5 18 32"
    "C19.8 25.5 22.4 28.2 24.6 32"
    "C26.8 35.8 28.6 33.2 31 32"
)
ARCOS = [
    ("M37.3 25.5A9 9 0 0 1 37.3 38.5", 1.0),
    ("M43.2 19.4A17.5 17.5 0 0 1 43.2 44.6", 0.7),
    ("M49.1 13.3A26 26 0 0 1 49.1 50.7", 0.4),
]
# Centro visual do desenho, para centralizar nos ícones.
CENTRO = (30.5, 32)


def tracos(cor, opacidades=(1.0, 0.7, 0.4), arcos=3, largura_onda=4.2,
           largura_arco=4.4):
    partes = [
        f'<path d="{ONDA}" stroke="{cor}" stroke-width="{largura_onda}" '
        'stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
    ]
    for (d, _), opacidade in list(zip(ARCOS, opacidades))[:arcos]:
        extra = "" if opacidade == 1 else f' stroke-opacity="{opacidade}"'
        partes.append(
            f'<path d="{d}" stroke="{cor}" stroke-width="{largura_arco}" '
            f'stroke-linecap="round" fill="none"{extra}/>'
        )
    return "".join(partes)


def centralizado(conteudo, escala, lado=64):
    cx, cy = CENTRO
    return (
        f'<g transform="translate({lado / 2} {lado / 2}) scale({escala}) '
        f'translate({-cx} {-cy})">{conteudo}</g>'
    )


def svg(conteudo, largura=64, altura=64, rotulo="FONAR"):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {largura} '
        f'{altura}" role="img" aria-label="{rotulo}">{conteudo}</svg>\n'
    )


arquivos = {}

# Símbolo solto, para fundo claro e para fundo escuro.
arquivos["fonar-simbolo.svg"] = svg(tracos(ROXO))
arquivos["fonar-simbolo-negativo.svg"] = svg(
    tracos(CREME, opacidades=(1.0, 0.72, 0.45))
)

# Ícone de app: quadrado de cantos arredondados, roxo, com o símbolo creme.
icone = (
    f'<rect width="64" height="64" rx="14" fill="{ROXO}"/>'
    + centralizado(tracos(CREME, opacidades=(1.0, 0.72, 0.45)), 0.8)
)
arquivos["fonar-icone.svg"] = svg(icone)

# Sangrado: o fundo ocupa tudo; quem arredonda é o sistema (iOS, ícone
# adaptável do Android, "maskable" da web). O símbolo cabe na zona segura.
sangrado = f'<rect width="64" height="64" fill="{ROXO}"/>' + centralizado(
    tracos(CREME, opacidades=(1.0, 0.72, 0.45)), 0.72
)
arquivos["fonar-icone-sangrado.svg"] = svg(sangrado)

# Favicon e tamanhos mínimos: sem o terceiro arco e com traço mais grosso,
# para continuar legível a 16 px.
favicon = (
    f'<rect width="64" height="64" rx="14" fill="{ROXO}"/>'
    + centralizado(
        tracos(CREME, opacidades=(1.0, 0.75), arcos=2, largura_onda=6,
               largura_arco=6.2),
        0.92,
    )
)
arquivos["fonar-favicon.svg"] = svg(favicon)

# macOS: o quadrado arredondado ocupa 824 de 1024, com margem transparente,
# como os ícones do sistema.
mac = (
    f'<rect x="100" y="100" width="824" height="824" rx="185" fill="{ROXO}"/>'
    f'<g transform="translate(100 100) scale({824 / 64})">'
    + centralizado(tracos(CREME, opacidades=(1.0, 0.72, 0.45)), 0.8)
    + "</g>"
)
arquivos["fonar-icone-macos.svg"] = svg(mac, 1024, 1024)
mac_pequeno = (
    f'<rect x="100" y="100" width="824" height="824" rx="185" fill="{ROXO}"/>'
    f'<g transform="translate(100 100) scale({824 / 64})">'
    + centralizado(
        tracos(CREME, opacidades=(1.0, 0.75), arcos=2, largura_onda=6,
               largura_arco=6.2),
        0.92,
    )
    + "</g>"
)


# Assinatura: símbolo + FONAR com as letras em contorno (Urbanist ExtraBold),
# para o arquivo valer sem a fonte instalada.
def palavra_em_contorno(texto, altura_maiuscula, x0, linha_de_base, espaco):
    fonte = TTFont(FONTE)
    glifos = fonte.getGlyphSet()
    cmap = fonte.getBestCmap()
    unidades = fonte["head"].unitsPerEm
    cap = fonte["OS/2"].sCapHeight or unidades * 0.7
    escala = altura_maiuscula / cap
    caminhos = []
    x = x0
    for letra in texto:
        nome = cmap[ord(letra)]
        caneta = SVGPathPen(glifos)
        glifos[nome].draw(
            TransformPen(caneta, (escala, 0, 0, -escala, x, linha_de_base))
        )
        caminhos.append(caneta.getCommands())
        x += glifos[nome].width * escala + espaco
    return " ".join(caminhos), x - espaco


def assinatura(cor_simbolo, cor_texto, opacidades):
    d, fim = palavra_em_contorno("FONAR", 32, 68, 48, 1.0)
    conteudo = (
        tracos(cor_simbolo, opacidades=opacidades)
        + f'<path d="{d}" fill="{cor_texto}"/>'
    )
    return svg(conteudo, round(fim + 4), 64)


arquivos["fonar-assinatura.svg"] = assinatura(ROXO, ROXO, (1.0, 0.7, 0.4))
arquivos["fonar-assinatura-negativo.svg"] = assinatura(
    CREME, CREME, (1.0, 0.72, 0.45)
)

for nome, conteudo in arquivos.items():
    (SAIDA / nome).write_text(conteudo, encoding="utf-8")


def png(svg_texto, lado, destino=None):
    dados = cairosvg.svg2png(
        bytestring=svg_texto.encode("utf-8"),
        output_width=lado,
        output_height=lado,
    )
    if destino:
        Path(destino).parent.mkdir(parents=True, exist_ok=True)
        Path(destino).write_bytes(dados)
    return dados


pngs = SAIDA / "png"
# Ícone geral (Android antigo, web "any", Windows grande).
for lado in (48, 72, 96, 144, 192, 512, 1024):
    png(arquivos["fonar-icone.svg"], lado, pngs / f"icone-{lado}.png")
# Sangrado (web "maskable", apple-touch).
for lado in (180, 192, 512):
    png(arquivos["fonar-icone-sangrado.svg"], lado, pngs / f"sangrado-{lado}.png")
# Favicon.
for lado in (16, 32, 48):
    png(arquivos["fonar-favicon.svg"], lado, pngs / f"favicon-{lado}.png")
# macOS.
for lado in (16, 32, 64, 128, 256, 512, 1024):
    fonte_mac = svg(mac_pequeno, 1024, 1024) if lado <= 32 else arquivos[
        "fonar-icone-macos.svg"]
    png(fonte_mac, lado, pngs / f"macos-{lado}.png")

# Windows: um .ico com vários tamanhos; os pequenos saem do favicon.
imagens = []
for lado in (256, 128, 64, 48, 32, 24, 16):
    fonte_ico = arquivos["fonar-favicon.svg"] if lado <= 32 else arquivos[
        "fonar-icone.svg"]
    imagens.append(Image.open(io.BytesIO(png(fonte_ico, lado))).convert("RGBA"))


def ico(imagens, destino):
    # Cada tamanho vai como PNG dentro do ICO (aceito desde o Windows Vista).
    blocos = []
    for imagem in imagens:
        buf = io.BytesIO()
        imagem.save(buf, format="PNG")
        blocos.append((imagem.size[0], buf.getvalue()))
    cabecalho = struct.pack("<HHH", 0, 1, len(blocos))
    deslocamento = 6 + 16 * len(blocos)
    entradas = b""
    corpo = b""
    for lado, dados in blocos:
        entradas += struct.pack(
            "<BBBBHHII",
            0 if lado >= 256 else lado,
            0 if lado >= 256 else lado,
            0, 0, 1, 32, len(dados), deslocamento + len(corpo),
        )
        corpo += dados
    Path(destino).write_bytes(cabecalho + entradas + corpo)


ico(imagens, pngs / "app_icon.ico")
print("ok:", sorted(arquivos), sorted(p.name for p in pngs.iterdir()))
