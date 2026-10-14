# Marca FONAR

O símbolo é uma **onda de voz que vira ondas de sonar**: fonoaudiologia mais
sonar, as duas metades do nome. A voz entra pela esquerda; as três ondas
saem dela e vão ficando mais claras, como o eco que volta. Escolhido em
14/10/2026 (US47), a direção "voz em eco".

Cores: roxo profundo `#40085E` e creme `#FFF7EB`; no tema escuro, o acento
`#D2B0EC`. Fonte da assinatura: Urbanist ExtraBold, em contorno.

## Os arquivos desta pasta

| Arquivo | Para quê |
|---|---|
| `fonar-simbolo.svg` | O símbolo, roxo, sobre fundo claro |
| `fonar-simbolo-negativo.svg` | O símbolo, creme, sobre fundo escuro ou roxo |
| `fonar-assinatura.svg` | Símbolo + FONAR, roxo |
| `fonar-assinatura-negativo.svg` | Símbolo + FONAR, creme |
| `fonar-icone.svg` | Ícone de app: quadrado de cantos arredondados, roxo |
| `fonar-icone-sangrado.svg` | O mesmo, sem cantos, para quem arredonda sozinho (iPhone, Android, web "maskable") |
| `fonar-icone-macos.svg` | O ícone com a margem dos ícones do macOS |
| `fonar-favicon.svg` | Para 16 e 32 px: sem a terceira onda, traço mais grosso |

Nada aqui é asset do Flutter: na tela, o símbolo é o `AppSimbolo`
(`lib/design_system/widgets/app_simbolo.dart`), desenhado em código para
tomar a cor do tema; no laudo em PDF, o `simboloDoFonarSvg` do mesmo
arquivo. Se o desenho mudar, mude os três juntos.

## Onde cada ícone está

`python3 tool/gerar_marca.py <saída> assets/fonts/Urbanist-ExtraBold.ttf`
gera os PNG e o ICO; daí se copiam para:

| Plataforma | Arquivo no app | Vem de |
|---|---|---|
| Android 8+ | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `drawable/ic_launcher_foreground.xml`, `values/ic_launcher_background.xml` | o símbolo em vetor, sobre o roxo (ícone adaptável) |
| Android antigo | `mipmap-*/ic_launcher.png` (48, 72, 96, 144, 192) | `png/icone-<lado>.png` |
| Windows | `windows/runner/resources/app_icon.ico` | `png/app_icon.ico` |
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_<lado>.png` | `png/macos-<lado>.png` |
| Web | `web/favicon.svg`, `web/favicon.png` | `fonar-favicon.svg`, `png/favicon-32.png` |
| Web | `web/icons/Icon-192.png`, `Icon-512.png` | `png/icone-<lado>.png` |
| Web | `web/icons/Icon-maskable-*.png`, `apple-touch-icon.png` | `png/sangrado-<lado>.png` |

A landing tem a sua cópia em `public/marca/` (favicon, ícone do iPhone,
imagem de compartilhamento e símbolo do cabeçalho).
