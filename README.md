# FONAR — aplicativo

<img src="marca/fonar-assinatura.svg" alt="FONAR" width="260">

Aplicativo do FONAR, plataforma de avaliação vocal clínica para
fonoaudiólogos, usada durante a consulta, com o paciente ao lado. TCC de
Engenharia de Software, PUC-Campinas.

**Um código só para Android, Windows, macOS (US41) e o navegador (US42, a
versão do iPhone)**, com exatamente as mesmas funções em todos.

> [!IMPORTANT]
> **`flutter run` abre o FONAR de verdade**, sem nenhum `--dart-define`: o
> login e o "Criar conta" no Firebase Authentication do projeto `fonar-763db`,
> e o cadastro, a análise e os resultados na API do Cloud Run (ver
> [Apontar para a API](#apontar-para-a-api)). Para olhar as telas sem rede, há
> o **modo de exemplo** (`--dart-define=FONAR_EXEMPLO=true`), com login,
> pacientes e resultados de exemplo, avisados na tela. O que falta, e de quem
> depende, está em [`PENDENCIAS.md`](PENDENCIAS.md).

**Sumário:** [O que o app faz](#o-que-o-app-faz) ·
[Regras inegociáveis](#as-duas-regras-arquiteturais-inegociáveis) ·
[Pré-requisitos](#pré-requisitos) · [Setup](#setup) ·
[Distribuição](#distribuição) · [Estrutura](#estrutura-de-pastas) ·
[Navegação](#navegação-como-uma-tela-leva-a-outra) ·
[Git](#convenções-de-git) · [Armadilhas](#armadilhas-conhecidas)

---

## O que o app faz

### O caminho de uma avaliação

Na ordem em que o profissional passa por ele:

1. **Entra** (US00) com e-mail e senha conferidos pelo Firebase (US32) e vê
   **os pacientes** (US01), com busca que não liga para acento.
2. **Cadastra o paciente** (US02) — ou corrige os dados depois (US20). Salvar
   avisa se já existe alguém com o mesmo nome e nascimento, e sair com o
   formulário preenchido pergunta antes (US21).
3. **Registra o consentimento** (US03). Sem ele, a gravação não abre: o
   bloqueio é do roteador, não um aviso. O paciente pode retirar o
   consentimento depois (US15), e aí a gravação volta a bloquear e os envios
   dele param.
4. **Afere o ruído da sala** (US04) com o medidor de nível ao vivo. Silêncio
   absoluto é tratado como microfone mudo, nunca como sala silenciosa.
5. **Grava as tarefas** (US05) — vogal sustentada e fala encadeada —, uma
   etapa por vez (US26): instrução grande para o paciente, cada WAV conferido
   depois de gravado, revisão antes de enviar e, no desktop, Espaço e R como
   atalhos. Dá para **ouvir** cada gravação (US13), e voltar no mesmo dia
   **retoma a sessão** (US16).
6. **Manda para a análise** pela **fila** (US06), que funciona sem conexão e
   sobe quando a rede voltar. Sessões que ficaram paradas no aparelho aparecem
   no perfil para enviar ou descartar (US19).
7. **Vê o resultado** (US07): AVQI e CPPS em destaque, as demais medidas
   menores, classificadas só se houver faixa de referência validada — hoje
   nenhuma há, e o app diz isso. O AVQI v03.01 vem da API, calculado sobre a
   vogal e a fala encadeada da sessão. O **espectrograma** abre em tela
   cheia, deitado no celular (US17), com pinça que amplia sem a página rolar
   junto (US55). O próximo passo — CAPE-V ou laudo — fica num rodapé fixo
   (US27).
8. **Registra a CAPE-V** (US08) numa régua de 100 mm, ouvindo a amostra — no
   celular, cada escala em tela cheia, para marcar deitado (US28) —, e a
   avaliação sobe para o Firebase quando há rede (US37). Vê a **evolução**
   entre sessões (US09), com um modo para mostrar ao paciente, e gera o
   **laudo em PDF** (US10), ao lado da pré-visualização A4 no desktop, que só
   é refeita quando o documento muda (US53).

### Em volta do caminho

- **Perfil do paciente** (US12): dados, consentimento, sessões, laudos e fila
  num lugar só, e as **anotações** (US51) — o registro do atendimento, com a
  data, sem rede inclusive, editáveis sem apagar (a edição é uma versão nova,
  e as de antes ficam à vista). Uma anotação pode deixar um **lembrete para a
  próxima consulta**, discreto num dia seguinte, no topo do perfil e no início
  da gravação, com o texto só ao tocar em "Mostrar" — o paciente às vezes vê a
  tela. As anotações não dependem do consentimento, que cobre a voz.
- **Histórico** (US23): as avaliações de todos os pacientes, por mês, para
  achar uma pelo quando.
- **Guia da primeira vez e Ajuda** (US50): na primeira vez de cada conta em
  cada aparelho, o guia mostra a tela inicial, um elemento por vez; a Ajuda o
  revê e lista os atalhos de teclado. Gravação, resultado, CAPE-V e laudo têm
  cada um uma dica de primeira vez.
- **Aparência**: tema escuro, do sistema ou escolhido na Conta (US30); no
  computador, a **interface cresce com a janela** — 120% num monitor Full HD
  —, com o ajuste "Tamanho da interface" (US48), e a entrada cresce e rola
  pela borda da janela (US49); **movimento funcional**, com transições curtas
  que somem no movimento reduzido do sistema, e as ações presas no rodapé só
  quando a tela tem altura para isso (US31).
- **Navegação**: a barra lateral e as abas ficam paradas, e só o conteúdo
  troca (US57). O **voltar** — o da tela e o do Android — leva sempre à tela
  de onde se veio, uma por vez, e na lista de pacientes fecha o app; no
  celular, nada fica embaixo da barra de status nem da dos botões (US60). Ver
  [Navegação](#navegação-como-uma-tela-leva-a-outra).

### Conta e acesso

- **Firebase Authentication pela API REST** (US32), o mesmo código em todas as
  plataformas. A sessão é da conta: cada envio da fila leva o id de quem
  gravou e só sobe na sessão dessa pessoa, o nome e o registro que vão no
  laudo são guardados por conta, e sair apaga a credencial do aparelho.
  Quando o Firebase não renova mais a sessão (senha trocada, conta
  desativada), a fila mostra "Entrar de novo", e o envio sobe sozinho depois
  da entrada.
- **Criar conta pelo app** (US34): e-mail, senha e a inscrição no Crefono;
  confirma o e-mail e já usa, enquanto a equipe confere a inscrição — ver
  [Criar conta e o primeiro acesso](#criar-conta-e-o-primeiro-acesso-us34).
- **Esqueci a senha** (US58): uma tela só para isso, com o e-mail da entrada
  já preenchido; o Firebase manda o link de redefinição. A **troca de senha**
  é na Conta (US45): o app confere a atual, troca no Firebase e guarda a
  credencial nova, que passa a valer também sem conexão.
- **Manter conectado neste aparelho** (US59): marcado na entrada, o app abre
  direto na conta até a pessoa sair. Não há bloqueio por inatividade (a US24
  saiu na US59): quem quer o aparelho fechado bloqueia o computador ou o
  celular, como faz com o resto.
- **Sem conexão**, entra no modo offline com a conta da última entrada, se
  houver pacientes no aparelho — com a senha, conferida por um verificador
  guardado no cofre na última entrada com rede (PBKDF2, nunca a senha).

### Dados e privacidade

- **Decisões jurídicas** (US43), pelo lado conservador: paciente menor de 18
  anos só é autorizado pelo responsável legal; a gravação feita sob um
  consentimento retirado não sobe mais, nem com um consentimento novo; e o
  perfil tem **eliminar os dados do paciente**, a pedido dele (LGPD, art.
  18), que apaga tudo aqui e no servidor. A exceção à senha em toda entrada,
  por decisão da equipe, é o "Manter conectado". O termo de consentimento e
  os termos de uso estão escritos sobre a LGPD, com revisão jurídica
  recomendada (`PENDENCIAS.md`).
- **Dados em repouso** (US44): no aparelho, o banco local é cifrado (SQLite3
  Multiple Ciphers, com a chave no cofre do sistema), e o banco de antes da
  atualização é cifrado na primeira abertura; o WAV sai do aparelho assim que
  chega ao servidor, e ouvir de novo vem da API.
- **Mais de um aparelho** (US40): os pacientes e os consentimentos da conta
  descem do Firebase na abertura, quando a conexão volta e quando alguém
  entra; a CAPE-V, os laudos e as anotações, quando o perfil do paciente
  abre; a gravação feita em outro aparelho se ouve pela API. Uma retirada de
  consentimento num aparelho bloqueia a gravação no outro. A descida só
  acrescenta ou atualiza o que não foi mudado aqui — nunca apaga, e nunca
  passa por cima de uma correção que ainda não subiu. Num **aparelho
  compartilhado**, cada paciente é de uma conta: quem entra vê só os seus, e
  a fila só os envios dela.

A numeração das US03 a US10 foi deduzida das telas do protótipo — confira com
o backlog antes de citar no texto do TCC (ver `PENDENCIAS.md`).

---

## As duas regras arquiteturais inegociáveis

Leia estas duas antes de escrever qualquer linha. Elas não são preferência de
estilo, e violar qualquer uma delas cria problema que não se conserta com
refatoração depois.

### 1. Nenhuma análise de áudio acontece no cliente

Toda medida acústica — f0, jitter, shimmer, HNR, CPPS, AVQI — é calculada **no
servidor**, pela API em Python que usa o motor do Praat através do
`parselmouth`. O aplicativo grava, envia e exibe o resultado. Nada mais.

**Por quê:** o `parselmouth` é licenciado sob GPL v3. Distribuir código GPL
dentro de um executável obriga a abrir o código do projeto inteiro. Executar
esse mesmo código como serviço remoto não caracteriza distribuição. A decisão
protege o modelo de negócio; não é escolha técnica e não está em discussão.

Na prática: **nunca adicione biblioteca de DSP, FFT ou análise de áudio ao
`pubspec.yaml`.**

Existe uma única exceção: leitura de amplitude em tempo real, para alimentar o
medidor de nível visual e a aferição de ruído ambiente, por exigência de
latência. Isso não é medida clínica e não entra no laudo.

### 2. A interface adapta por largura de tela, nunca por sistema operacional

Use `LayoutBuilder` com os breakpoints de
`lib/design_system/breakpoints.dart`. **É proibido usar `Platform.isAndroid` ou
`Platform.isWindows` para decidir layout.**

**Por quê:** o eixo real é espaço disponível, não sistema. Um tablet Android em
paisagem e uma janela de notebook Windows têm a mesma largura e devem receber o
mesmo layout. Decidir por SO produz duas interfaces que divergem sozinhas ao
longo do tempo, e nenhuma das duas fica certa em tablet.

As faixas são `compacta` (< 600), `media` (< 1024) e `expandida`.

---

## Pré-requisitos

As versões abaixo são as da máquina onde o projeto foi montado e verificado,
não mínimos teóricos. Se a sua for diferente e algo quebrar, comece comparando
aqui.

| | Versão verificada |
|---|---|
| Flutter | 3.47.2 (canal stable) |
| Dart | 3.13.2 (vem junto do Flutter) |
| Android SDK | 36.1.0 — platform `android-36.1`, build-tools 36.1.0 |
| JDK | OpenJDK 21 (o que vem junto do Android Studio serve) |
| Gradle | 9.3.1 (via wrapper, baixado sozinho no primeiro build) |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |
| Visual Studio | Community 2022 17.14.37710.0, com a carga de C++, o componente ATL e o Windows 10 SDK 10.0.26100.0. É o que está na máquina de referência; a 2026 também serve desde 24/09/2026 |

O projeto compila para `minSdk 24`, `targetSdk 36` e `compileSdk 36` — valores
herdados do Flutter, não fixados à mão em `android/app/build.gradle.kts`.

### Para build Android

Android Studio, ou o Android SDK sozinho via linha de comando. O JDK embutido no
Android Studio já resolve — não instale outro Java só por causa disto.

### Para build Windows: leia isto antes de tentar

**Você precisa do Visual Studio** — a Community serve, e qualquer versão
corrente também — **com duas coisas marcadas:**

- a carga de trabalho **"Desenvolvimento para desktop com C++"**
  (*Desktop development with C++*);
- dentro dela, o componente **"ATL do C++ para as ferramentas de build v143
  mais recentes"** (*C++ ATL for latest v143 build tools*).

Este é o passo que mais trava quem chega no projeto, por quatro motivos:

1. **Não é o VS Code.** Visual Studio e Visual Studio Code são produtos
   diferentes, de nomes parecidos. Ter o VS Code instalado não ajuda em nada
   aqui: o build do Windows precisa do compilador MSVC, que só vem no Visual
   Studio.
2. **É download de vários GB e demora.** Reserve tempo e banda. Não dá para
   fazer isso quinze minutos antes da reunião.
3. **Instalar o Visual Studio não basta — a carga C++ é um item que você marca
   durante a instalação.** Uma instalação padrão, sem essa marcação, atravessa
   todas as telas e só falha depois, na hora do build. Se já instalou sem
   marcar, abra o *Visual Studio Installer*, clique em *Modificar* e adicione a
   carga.
4. **A carga C++ também não basta — o ATL é um componente à parte, e vem
   desmarcado.** Sem ele falta o header `atlstr.h`, e o
   `flutter_secure_storage_windows` — que guarda o token no Gerenciador de
   Credenciais — não compila. O erro cita o `atlstr.h` e não diz uma palavra
   sobre ATL, então não é óbvio o que marcar.
   No *Visual Studio Installer* → *Modificar* → aba **Componentes
   individuais**, busque por `ATL` e marque a opção de v143 mais recente.
Se preferir o **Build Tools for Visual Studio**, a mesma cadeia de compilação
sem a IDE, serve igual — com a mesma carga de C++ e o mesmo componente ATL.

Confirme com `flutter doctor -v`: a linha de Visual Studio precisa estar com
`[√]`.

> **Mudou em 24/09/2026.** Até essa data o projeto exigia o Community 2022,
> especificamente, porque o `just_audio_windows` não compilava no MSVC 14.51
> do Visual Studio 2026. Esse plugin saiu do projeto — quem toca as gravações
> agora é o `audioplayers` — e a restrição de versão morreu junto. Se você
> tinha removido a instalação de 2026 por causa do FONAR, pode trazê-la de
> volta.

#### O Flutter escolhe sozinho qual Visual Studio usar

Vale saber, porque continua valendo: **o Flutter pega a instalação mais recente
do Visual Studio e não oferece opção de trocar.** Não existe flag de linha de
comando nem variável de ambiente para apontar qual usar. Com duas instalações
na máquina, é sempre a mais nova que compila, e nenhuma mensagem de erro diz
isso. Quando o build quebrar de um jeito que não faz sentido, o
`flutter doctor -v` é o que revela qual instalação ele enxergou.

Hoje isso não derruba o build — foi problema enquanto o `just_audio_windows`
existia aqui, e ele saiu. Fica o registro para o dia em que algum outro plugin
implicar com uma versão de compilador.

Nada disso aparece em `flutter test`: os testes rodam em Dart e nunca compilam
código nativo. Quebra de build só aparece em `flutter build windows` — por isso
o CI tem um job de Windows, descrito na seção de integração contínua.

---

## Setup

```bash
git clone https://github.com/fonar-project/fonar-app.git
cd fonar-app
flutter pub get
```

`flutter pub get` também gera o `android/local.properties`, que aponta para o
seu SDK do Android e para a sua instalação do Flutter. Ele é ignorado pelo git
de propósito: os caminhos são da sua máquina.

### Rodar

```bash
flutter run -d windows       # desktop Windows
flutter run -d android       # dispositivo ou emulador Android conectado
flutter run                  # escolhe sozinho se só houver um dispositivo
flutter devices              # lista o que está disponível agora
```

O primeiro `flutter run -d windows` compila código nativo e demora bem mais que
os seguintes. O primeiro build Android baixa o Gradle 9.3.1 e as dependências —
mesma história.

O primeiro build de cada plataforma também baixa o SQLite pronto do banco
local (conferido por SHA-256) e, no Windows, o pdfium da pré-visualização do
laudo: precisa de rede nessa hora. Depois, o app funciona sem conexão.

### Verificar antes de commitar

```bash
dart format .                # o CI reprova código fora do formato padrão
flutter analyze --fatal-infos  # precisa terminar com "No issues found!"
flutter test                 # roda a suíte
flutter test test/widget_test.dart                            # um arquivo
flutter test --plain-name "app sobe e abre na rota inicial"   # um teste
```

Mexeu em ícone — adicionou, removeu ou redesenhou um SVG? Rode também
`dart run tool/compilar_icones.dart` e commite o que sair dele. O motivo está
logo abaixo.

Mexeu numa tabela do banco (`lib/core/banco/tabelas.dart`)? Gere o código de
novo e commite junto:

```bash
dart run build_runner build
dart format lib/core/banco
```

Se a mudança vai para quem já tem o app instalado, suba o `schemaVersion`,
escreva a migração e guarde o formato novo — o passo a passo está no
comentário de `schemaVersion`, em `lib/core/banco/banco_local.dart`.

### Integração contínua

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) roda a cada push e a
cada pull request, com o mesmo Flutter 3.47.2 da tabela de pré-requisitos, em
cinco jobs. Nenhum publica artefato — quem publica é o `release.yml`, por tag
(ver [Distribuição](#distribuição)).

#### `verificacao`, em `ubuntu-latest`

| Passo | Comando |
|---|---|
| Dependências | `flutter pub get` |
| Formatação | `dart format --output=none --set-exit-if-changed .` |
| Análise | `flutter analyze --fatal-infos` |
| Testes | `flutter test` |
| Código do banco | `dart run build_runner build`, e `lib/core/banco` precisa ficar igual |
| Ícones pré-compilados | `dart run tool/compilar_icones.dart`, e a árvore precisa ficar limpa |

Toda falha vira anotação no PR, no arquivo e na linha
([`tool/ci_anotacoes.py`](tool/ci_anotacoes.py)): o diff do formato, o aviso
da análise e, de cada teste que falha, o que o `flutter_test` imprimiu — o
esperado e o encontrado —, sem precisar abrir o log.

O último passo existe para cobrir o buraco que o
`test/design_system/app_icone_test.dart` não cobre. Aquele teste compara nomes
de arquivo, então enxerga `.vec` faltando e `.vec` órfão — mas não enxerga
`.vec` **desatualizado**, aquele que existe, tem o nome certo e mesmo assim não
corresponde mais ao desenho do SVG.

O CI resolve recompilando. Se os binários estavam em dia, o compilador
reescreve bytes idênticos e o `git status` continua limpo. Se algum estava
velho, o arquivo muda e o CI acusa. Quando isso acontece, a correção é rodar
`dart run tool/compilar_icones.dart` na sua máquina e commitar o resultado — a
própria mensagem de erro do CI diz isso.

#### `build-windows`, em `windows-latest`

Roda `flutter build windows` e mais nada. Compila, não empacota e não sobe
artefato — o que interessa é ter compilado.

Existe porque **os testes não pegam quebra de compilação nativa, e nunca vão
pegar**: `flutter test` roda Dart, no Ubuntu, sem chamar o MSVC uma vez
sequer. A suíte inteira passa verde com o build do Windows em frangalhos — foi
o que aconteceu com o ATL faltando e com o `just_audio_windows` contra o
compilador do Visual Studio 2026. Compilar de verdade, numa máquina Windows, é
o único jeito de enxergar isso antes do usuário.

A imagem voltou a ser a `windows-latest` em 24/09/2026. Ela tinha sido fixada
em `windows-2025` porque a corrente passou a trazer o Visual Studio 2026, que
não compilava o `just_audio_windows`; com esse plugin fora do projeto, fixar a
imagem só serviria para esconder regressão em vez de acusá-la — que é o motivo
de o job existir. O passo `flutter doctor -v` está lá justamente para o log
dizer qual Visual Studio foi usado.

#### `build-android` e `build-macos`

Pelo mesmo motivo do `build-windows`: o Gradle e o Xcode também não passam
pelos testes. O Android compila em debug (sem precisar da chave de release),
no Ubuntu com o JDK 17; o macOS, em debug, no `macos-latest`.

#### `build-web`

O mesmo, para o navegador (US42): baixa o banco do navegador
(`tool/preparar_web.sh`), roda `flutter build web` como o release roda e gera
a lista do modo offline (`tool/lista_offline.py`). Os testes rodam na VM do
Dart, onde `lib/core/navegador/navegador_web.dart` nem compila; só este job
o compila.

Ao subir a versão do Flutter, mude em todos os lugares: na tabela de
pré-requisitos, nos `flutter-version` dos jobs do `ci.yml` e do `gerar.yml`, e
no `FLUTTER_VERSAO` do `release.yml`. Se divergirem, o CI passa a validar um
Flutter que ninguém usa.

### Apontar para a API

O app já vem apontado para a API de produção, no Cloud Run
(`https://fonar-api-97444293253.southamerica-east1.run.app`), e para o
Firebase do projeto `fonar-763db` — `flutter run -d windows` e pronto (ver
`lib/core/config/app_config.dart`). Nenhum dos dois é segredo: a URL é
pública, a chave do Firebase vai dentro de todo app cliente, e quem protege os
dados são as regras do Firestore e a API, que conferem o token.

Para desenvolver, o build ainda troca cada um:

```bash
# a API rodando na sua máquina (uvicorn web.main:app, no fonar-api)
flutter run -d windows --dart-define=FONAR_API_BASE_URL=http://localhost:8080

# modo de exemplo: sem rede, com login, pacientes e resultados de exemplo
flutter run -d windows --dart-define=FONAR_EXEMPLO=true
```

O envio da fila segue o contrato da ADR-014 da API (US33):

1. antes do primeiro WAV, o paciente, o livro de consentimentos e a sessão
   sobem para o Cloud Firestore, pela API REST e com o token de quem está
   na sessão (`lib/features/sincronizacao/`), no formato que as regras de
   segurança aceitam. A API confere o consentimento lá;
2. cada gravação vai em `POST /v1/pacientes/{p}/sessoes/{s}/amostras`, com
   o id da amostra, que torna o reenvio seguro;
3. o id da análise é o id da sessão.

Sem consentimento em vigor no Firebase, a API responde
`409 consentimento_ausente`, e o envio para como numa retirada.

A **CAPE-V** registrada também sobe (US37), direto para o Firestore, em
`sessoes/{s}/avaliacoes/cape_v` (ADR-017 da API), no formato que as regras
aceitam (`lib/features/cape_v/data/cape_v_no_firestore.dart`). Sobe só a da
sessão que a conta na sessão mandou para a análise, porque é na árvore dela
que a sessão existe. Tenta ao abrir o app, quando a rede volta, quando alguém
entra e logo depois de cada registro; registrar de novo substitui a de lá,
a não ser que a de lá seja mais nova. A registrada em outro aparelho desce
quando o perfil do paciente abre (US40,
`lib/features/sincronizacao/data/descida_firestore.dart`).

O **laudo emitido** não muda nem some (US38, ADR-018 da API). Cada emissão
é um documento com número próprio — os oito primeiros caracteres de um
UUID, impressos no PDF e no nome do arquivo —, e emitir de novo cria outro,
que diz, impresso, qual substitui. O anterior continua guardado e sai como
foi emitido. A cópia de cada laudo sobe para a API
(`POST /v1/pacientes/{p}/sessoes/{s}/laudos`, com o PDF byte a byte), do
mesmo jeito que a CAPE-V: só os de sessão enviada pela conta na sessão, ao
abrir o app, quando a rede volta, quando alguém entra e logo depois de cada
emissão (`lib/features/laudo/data/laudos_na_api.dart`). A tela diz se a
cópia já está no servidor. O PDF leva o espectrograma da vogal, a imagem
que a API calculou; se ela não vier, o documento diz que ficou de fora.

Para tirar o PDF do aplicativo, o desktop usa "Salvar como"
(`file_selector`): nada fica na pasta temporária. No celular, a folha de
compartilhar do sistema precisa de um arquivo no cache, e ele é apagado na
abertura seguinte (`limparPdfsCompartilhados`).

Fora do modo de exemplo, os resultados também vêm da API
(`lib/features/analise/data/repositorio_analises_api.dart`): a análise da
sessão e a evolução do paciente, com os valores do motor da gravação da
vogal sustentada (jitter e shimmer convertidos de fração para %; CPPS em dB).
Faixa provisória da API não classifica: a medida aparece com o valor e "sem
faixa validada", como a regra das faixas pede. O **AVQI** é da sessão, não de
uma gravação: a API roda o script oficial do AVQI v03.01 sobre a vogal e a
fala encadeada e o manda em `resultado_da_sessao` (ADR-016 do `fonar-api`).
Sem as duas tarefas, ou se a API não pôde calcular, ele aparece como "não
calculado". O
**espectrograma** é o PNG que a API gera da gravação da vogal
(`GET .../amostras/{a}/espectrograma`), buscado pelo mesmo cliente das outras
chamadas, com o token (`ImagemDaApi`, em
`lib/features/analise/data/imagem_do_servidor.dart`). Os pacientes e
resultados de exemplo só aparecem no modo de exemplo.

### Conectar ao Firebase (autenticação)

O login fala com o Firebase Authentication pela **API REST**, com o Dio que
já estava no projeto. Não usamos o plugin `firebase_auth`: ele declara o
Windows como "só para desenvolvimento, produção não suportada", e a regra do
projeto é que Android e Windows têm as mesmas funcionalidades. Por isso não há
`google-services.json` nem `firebase_options.dart` — o app só precisa da
**chave Web API** do projeto `fonar-763db`, que já está em
`lib/core/config/app_config.dart`.

**No console do Firebase** (uma vez, por quem administra o projeto):

1. **Authentication → Sign-in method → E-mail/senha**: ativar. Só a primeira
   opção; o "link por e-mail" não é usado.
2. As contas nascem **pelo próprio app** (US34, "Criar conta" na entrada) —
   não precisa criar no console. Para teste, dá para criar lá também
   (**Authentication → Users → Adicionar usuário**); no primeiro acesso, o app
   pede a confirmação do e-mail e o cadastro.
3. **Configurações do projeto → Geral → Chave de API da Web**: é a chave que
   está em `app_config.dart` (`_chaveDeProducao`). Trocou de projeto, troque
   lá.
4. Recomendado: **Authentication → Modelos**, conferir em português os textos
   de **Redefinição de senha** e de **Verificação de endereço de e-mail**. O
   app pede os dois e-mails em pt-BR.
5. **Recomendado, já que a chave está no repositório público**: no Google
   Cloud Console, em **APIs e serviços → Credenciais**, restringir essa chave
   às APIs **Identity Toolkit** e **Token Service**. Assim ela só serve para
   entrar, criar conta e renovar o token, e mais nada no projeto.

Para apontar um build para outro projeto, a chave e a URL ainda entram por
`--dart-define` (`FONAR_FIREBASE_API_KEY`, `FONAR_API_BASE_URL`), na linha ou
num arquivo fora do git — `dart_defines.json` está no `.gitignore`:

```bash
flutter run -d windows --dart-define-from-file=dart_defines.json
```

### Criar conta e o primeiro acesso (US34)

O cadastro é **aberto**: qualquer pessoa com e-mail cria a conta pelo app e já
usa o sistema, como **pendente**; a equipe confere depois a inscrição no
Crefono e marca o cadastro como **credenciado** (ADR-015 da API; a equipe usa
`tools/credenciar_profissional.py`, no `fonar-api`). A situação não bloqueia
nada: o app só a mostra.

```
Criar conta  ->  e-mail, senha, nome, região do Crefono, número e o aceite
             ->  o Firebase cria a conta e manda o link de verificação
Confirme seu e-mail  ->  "Já confirmei": token novo, e o cadastro vai à API
                     ->  entra, como "inscrição em conferência"
```

A API conduz o primeiro acesso (`GET /v1/profissionais/eu`): sem e-mail
verificado, o app pede a confirmação; verificado e sem cadastro, mostra o
formulário (`/completar-cadastro`) — é o caminho de quem fechou o app antes de
confirmar, de conta criada no console, e do cadastro antigo, do tempo do
convite (`cadastro_completo: false`), que o mesmo `POST` completa. Com a API
fora do ar, a entrada segue como antes — o app funciona sem rede, e a fila
espera.

Na Conta, nome e registro vêm do cadastro na API e são salvos lá (o registro
no formato "CRFa 2-12345"); trocar a região ou o número de quem já foi
credenciado volta para a conferência, e a tela avisa antes. A situação do
credenciamento aparece embaixo do e-mail.

No **modo de exemplo** (`--dart-define=FONAR_EXEMPLO=true`), o app roda com o
**login de exemplo**: aceita qualquer e-mail e senha, cada e-mail vira uma
conta "exemplo:…", e a tela de entrada avisa; os pacientes e os resultados
também são os de exemplo. É como rodam os testes e o CI
(`test/flutter_test_config.dart`), e serve para olhar as telas sem rede. Um
build de **distribuição** (`--release`) nesse modo se recusa a abrir: seria
dado de saúde aberto a qualquer senha.

---

## Distribuição

O FONAR é baixado do **GitHub Releases** deste repositório (US41), e a landing
page aponta para o último release — o link não muda a cada versão:

| Plataforma | Arquivo | O que é |
|---|---|---|
| Windows 10 e 11 | `FONAR-Windows.zip` | a pasta do `flutter build windows --release`; descompacta e abre `fonar_app.exe` |
| macOS | `FONAR-macOS.zip` | o `FONAR.app`, empacotado com `ditto` |
| Android | `FONAR-Android.apk` | o APK de release, só de 64 bits (arm64), instalado direto (US54). A landing leva à página da versão, onde se toca no APK: baixado por um link direto, ele caía numa janela à parte do navegador do celular e parava em 100% |
| Android de entrada | `FONAR-Android-32bits.apk` | o mesmo APK para celular com sistema de 32 bits (os Android Go, por exemplo); a landing o indica quando o celular diz que o app não é compatível |
| iPhone e iPad | — | a versão web, em <https://fonar-project.github.io/fonar-app/>, adicionada à Tela de Início pelo Safari (US42) |

**Publicar uma versão:** na `main` atualizada, `git tag vX.Y.Z` e
`git push origin vX.Y.Z` — o número sobe na correção (`Z`) ou na
funcionalidade nova (`Y`). O [`release.yml`](.github/workflows/release.yml)
compila as três plataformas, cada uma na sua máquina, publica o release com
as instruções de primeira abertura e põe a versão web no GitHub Pages. A
versão do app é a da tag, e a landing passa a baixar a nova sozinha.

### A versão web (iPhone e iPad)

Não há conta paga de desenvolvedor da Apple, e sem ela não se instala app
nativo no iPhone. A versão do iPhone é, por isso, **o mesmo app compilado
para o navegador**, publicada no GitHub Pages e adicionada à Tela de Início
pelo Safari (*Compartilhar → Adicionar à Tela de Início*). Mesmas telas,
mesmas regras, mesma API.

- **A trava da captura.** No navegador, quem decide o processamento do
  microfone é o navegador. Antes de medir o ruído, o app abre o microfone com
  ganho automático, supressão de ruído e cancelamento de eco desligados e lê
  o que o navegador **diz ter aplicado** (`getSettings()`); a cada gravação,
  confere de novo pelo aviso do `record`. Se algum ficou ligado — ou se o
  cancelamento de eco nem é relatado —, a gravação não abre, e a tela diz o
  que ficou ligado (`naoConfirmadosDesligados`, em
  `captura/domain/processamento_automatico.dart`). O Safari relata só o
  cancelamento de eco, porque nele os três são um processamento só; essa
  premissa está nas conferências de aparelho do `PENDENCIAS.md`.
- **Os dados.** O banco local é o mesmo SQLite, compilado para WebAssembly
  (`web/sqlite3.wasm`, num worker, `web/drift_worker.js`), guardado no
  armazenamento da página; os WAV moram nele (tabela `audios_do_navegador`),
  porque não há pasta de arquivos. Os dois binários não são versionados:
  `bash tool/preparar_web.sh` os baixa da release do drift que o
  `pubspec.lock` fixou. O app pede ao navegador para não limpar esses dados
  sozinho, e não abre a gravação se o navegador não oferecer onde guardá-los.
- **Sem internet.** O `web/servico_offline.js` guarda a versão inteira na
  primeira abertura; daí em diante a página abre sem rede, e a fila sobe
  quando a conexão volta. A lista do que guardar sai do build
  (`python3 tool/lista_offline.py build/web`).
- **Uma vez, à mão:** ligar o GitHub Pages do repositório em *Settings →
  Pages → Source: GitHub Actions*. Sem isso, o job da versão web falha e o
  resto do release sai igual. A API só aceita chamada do navegador vinda de
  `https://fonar-project.github.io` (CORS, no `web/main.py` da API).

Para rodar na sua máquina: `bash tool/preparar_web.sh` e `flutter run -d
chrome`. Para servir o build, `flutter build web --base-href /fonar-app/
--no-web-resources-cdn` e um servidor estático em `build/web` — e
`FONAR_ORIGENS_WEB` na API, se ela também for a local.

**Sem assinatura de código, de propósito.** Não há certificado de assinatura
para o Windows nem conta paga de desenvolvedor da Apple. Por isso:

- no **Windows**, a primeira abertura pode mostrar o SmartScreen ("O Windows
  protegeu o computador"): *Mais informações* → *Executar assim mesmo*;
- no **macOS**, o app sai com a assinatura local do Xcode e sem notarização:
  na primeira abertura, *Ajustes → Privacidade e Segurança* → *Abrir Mesmo
  Assim*. O cofre da credencial usa o keychain comum do usuário
  (`usesDataProtectionKeychain: false`), porque o de proteção de dados exige
  uma equipe de desenvolvedor. O sandbox do app libera só rede (cliente),
  microfone, salvar o arquivo que o profissional escolhe e imprimir.

**A chave do Android.** Um APK só instala por cima de outro assinado pela
mesma chave — perder a chave é não conseguir mais atualizar quem já instalou.
Ela nunca entra no repositório. Para criar e guardar como secrets (uma vez, na
máquina de quem publica, com o JDK e o `gh` logado):

```bash
keytool -genkeypair -v -keystore fonar.jks -alias fonar \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -dname "CN=FONAR, O=FONAR, C=BR"
base64 -w0 fonar.jks | gh secret set FONAR_ANDROID_KEYSTORE_BASE64 -R fonar-project/fonar-app
gh secret set FONAR_KEYSTORE_SENHA -R fonar-project/fonar-app   # a senha do keystore
gh secret set FONAR_CHAVE_ALIAS -R fonar-project/fonar-app --body fonar
gh secret set FONAR_CHAVE_SENHA -R fonar-project/fonar-app      # a senha da chave
```

No PowerShell, o `base64` é
`[Convert]::ToBase64String([IO.File]::ReadAllBytes("fonar.jks")) | gh secret set FONAR_ANDROID_KEYSTORE_BASE64 -R fonar-project/fonar-app`.
Guarde o `fonar.jks` e as senhas fora do computador também. Sem os secrets, o
release sai com a chave de debug e avisa: serve para testar, não para
distribuir. Para um APK de release na sua máquina, crie `android/key.properties`
(ignorado pelo git) com `storeFile`, `storePassword`, `keyAlias` e
`keyPassword`.

## Verificando o ambiente

```bash
flutter doctor        # panorama
flutter doctor -v     # caminhos e versões, necessário para diagnosticar
```

### "Android SDK not found"

O Flutter procura o SDK em locais conhecidos e nas variáveis de ambiente. Se
você instalou fora do padrão, aponte na mão:

```bash
flutter config --android-sdk "C:\caminho\para\o\Android\sdk"
```

Na máquina de referência o SDK está em `C:\Android`. O diretório certo é o que
contém as pastas `platforms/` e `build-tools/`.

Aparentado: se o Flutter não achar o Java, use
`flutter config --jdk-dir="caminho/para/o/jdk"`. O JDK do Android Studio
costuma estar em `C:\Program Files\Android\Android Studio\jbr`.

### "Android license status unknown" / licenças não aceitas

```bash
flutter doctor --android-licenses
```

Responda `y` em cada uma. São várias. Se o comando não abrir, é sinal de que o
Flutter ainda não achou o SDK — resolva o item anterior primeiro.

### Chrome com `[X]`

O `flutter doctor` reclama do Chrome ausente porque verifica o alvo web. A
versão web (US42) é alvo do projeto, mas só precisa do Chrome quem for rodá-la
na própria máquina (`flutter run -d chrome`); o build dela roda no CI. Para
Android e Windows, o que precisa estar verde é Flutter, Android toolchain e
Visual Studio.

---

## Estrutura de pastas

```
lib/
├── main.dart              o container do Riverpod, a sessão mantida (US59)
│                          e o FonarApp
├── app/
│   ├── app.dart           MaterialApp.router, tema, sem lógica
│   ├── app_estrutura.dart navegação principal (barra no celular, lateral
│   │                      no desktop), montada pelo ShellRoute do roteador
│   ├── licencas.dart      licença da fonte, para "Licenças de software"
│   └── router/            rotas; a navegação (abrir, substituir, voltar) e o
│                          voltar do Android; o bloqueio de consentimento e
│                          a pergunta antes de sair de formulário alterado
├── core/                  infraestrutura, sem regra de negócio
│   ├── banco/             o banco local (Drift): tabelas, migração, ids
│   ├── auth/              Firebase Auth pela API REST, credencial e token
│   ├── config/            URL da API, chave do Firebase, timeouts e versão
│   ├── error/             AppException selado; erro traduzido para o usuário
│   ├── navegador/         o que só o navegador responde (US42), por
│   │                      importação condicional
│   ├── network/           cliente Dio, interceptors e estado da conexão
│   ├── offline/           se dá para entrar sem conexão
│   ├── storage/           o token, no cofre do sistema
│   └── permissions/       contrato de permissão de microfone
├── design_system/         tudo que é aparência
│   ├── tokens/            cor, espaçamento, tipografia, raio
│   ├── theme/             ThemeData montado a partir dos tokens
│   ├── widgets/           componentes compartilhados (botão, campo,
│   │                      situação, confirmação, ícone…)
│   └── breakpoints.dart   as faixas de largura (regra 2)
├── l10n/
│   └── app_strings.dart   TODO texto de interface, em pt-BR
└── features/              uma pasta por funcionalidade
    ├── auth/              entrada, sessão por conta (e a mantida) e perfil
    ├── cadastro/          criar conta e o primeiro acesso (US34)
    ├── pacientes/         lista, cadastro, perfil e correção dos dados
    ├── consentimento/     registro e retirada
    ├── captura/           aferição, gravação, retomada e sessões paradas
    ├── reproducao/        ouvir uma gravação
    ├── fila/              envio para a análise, com e sem conexão
    ├── analise/           resultado, faixas de referência, espectrograma
    ├── cape_v/            a escala perceptivo-auditiva
    ├── historico/         histórico geral, evolução e modo paciente
    ├── laudo/             conferência, PDF, compartilhar e imprimir
    ├── anotacoes/         anotações do paciente e o lembrete da consulta
    ├── guia/              o guia da primeira vez e a Ajuda
    ├── sincronizacao/     o que sobe para o Firestore e o que desce (US33, US40)
    └── conta/             dados do profissional, senha, aparência e sair

test/
├── apoio/                 banco em memória e repositórios falsos
├── core/migracoes/        o formato de cada versão do banco (gerado)
└── …                      o mesmo desenho de lib/

web/                       a página da versão web (US42): index.html,
                           manifest, o service worker do modo offline
tool/                      ícones, anotações do CI e o preparo da versão web
```

**Divisão por feature, não por camada.** Cada pasta em `features/` se divide em
três:

- `domain/` — modelos e contratos da funcionalidade. Não conhece Dio, nem
  Flutter, nem banco.
- `data/` — implementação: chamada de API, cache, mapeamento. Depende de
  `core/network`.
- `presentation/` — telas, widgets e providers. **Widgets não carregam regra de
  negócio.**

O que justifica essa divisão: mexer numa funcionalidade toca uma pasta, não seis
lugares distantes. E o limite entre features fica visível — se `captura/`
precisa importar de dentro de `pacientes/data/`, é sinal de que aquilo era
`core/` ou `domain/` desde o começo.

**`core/`** é infraestrutura que qualquer feature usa e que não pertence a
nenhuma delas. Se algo em `core/` só serve a uma feature, o lugar dele é dentro
da feature.

**`design_system/`** concentra a aparência. Telas não inventam cor, espaçamento
nem raio de borda: puxam dos tokens, que seguem a paleta e a tipografia do
CLAUDE.md. Assim, trocar a identidade visual é trabalho num lugar só.

**`core/banco/`** é o banco local, um só para o app inteiro: pacientes,
consentimentos (e retiradas), gravações, fila, CAPE-V e laudos. É o que
deixa o consultório sem sinal trabalhar. As tabelas guardam enum como texto,
e quem converte de e para o domínio é o repositório de cada feature, na
camada `data/`. Os testes usam o mesmo banco, em memória
(`test/apoio/banco_em_memoria.dart`).

**`l10n/app_strings.dart`** guarda todo texto visível, incluindo as mensagens de
erro. Dois motivos: revisão da linguagem clínica em um arquivo só, e nenhum
literal solto para caçar depois. Vale a regra de produto — o sistema é
ferramenta de apoio à decisão, **nunca emite diagnóstico**, e nenhum texto pode
sugerir o contrário.

---

## Navegação: como uma tela leva a outra

A regra é a do voltar: **o voltar — o da tela e o do Android — leva sempre à
tela de onde se veio, uma de cada vez** (US60). Por isso as telas não navegam
pelo `go` do go_router, que monta a pilha pela hierarquia das rotas (quem
abria a avaliação pelo Histórico, e dela a CAPE-V, voltava da CAPE-V para a
avaliação e dali para o perfil do paciente, que nunca esteve no caminho).
Navegam pelos verbos de
[`lib/app/router/navegacao.dart`](lib/app/router/navegacao.dart):

| Verbo | Quando | O voltar de lá |
|---|---|---|
| `context.abrir(...)` | a ida comum: tocar num item, num botão | a tela de onde se veio |
| `context.substituir(...)` | o fim de uma tarefa: o cadastro salvo, o consentimento registrado, a gravação enviada | a tela de antes da tarefa — o formulário concluído não volta |
| `context.voltarOu(...)` | o voltar da tela, e o "salvar" que devolve à tela de baixo | a tela de baixo; aberta pelo endereço (na web), a de onde normalmente se chega |
| `context.irAoDestino(...)` | as abas e a barra lateral | entre as listas, a aba anterior; saindo de uma tarefa, a pilha recomeça, e o formulário alterado pergunta antes |

O `go` fica para **recomeçar** a pilha, quando o que estava nela deixou de
valer: entrar e sair da conta, o paciente eliminado, a rota que não existe, a
trilha do desktop.

A tela que fica sozinha na pilha (aberta pelo `go`) tem o
[`VoltarDoSistema`](lib/app/router/voltar_do_sistema.dart): o voltar do
Android leva à lista de pacientes — ou, antes de entrar, à entrada —, e só na
lista e na entrada fecha o app. O `test/app/voltar_do_sistema_test.dart`
confere tudo isso mandando o voltar como o Android manda (`popRoute`).

O voltar preditivo do Android 16 está **desligado** no manifesto
(`enableOnBackInvokedCallback="false"`): com o app mirando a API 36, o sistema
só entregava o voltar quando o Flutter avisava que tinha para onde voltar, e
o app fechava no meio do uso. Religar só depois de conferir num Android 16 de
verdade (`PENDENCIAS.md`).

---

## Convenções de git

**Branch:** `nome/USxx-featureImplementada`

```
felipe/US04-medidorDeNivel
```

**Commit:** Conventional Commits, em português, referenciando a User Story.

```
feat(US04): adiciona medidor de nivel em tempo real
fix(US07): corrige envio duplicado ao perder conexao
```

A feature branch sai da `main`. Enquanto os PRs anteriores não entram, cada
US sai da branch da US anterior, e os PRs se empilham na mesma ordem.

**Sem atribuição de IA** em nada que vai para o repositório — mensagem de
commit, descrição de PR, comentário: nada de `Co-Authored-By: Claude`,
"Generated with Claude Code" ou link de sessão. O autor do commit é sempre a
pessoa que pediu a alteração.

---

## Armadilhas conhecidas

### Microfone no Windows pode falhar em silêncio, com áudio mudo

O modo de falha mais perigoso do projeto. Um app Win32 desempacotado — que é o
que `flutter build windows` gera — **não declara capacidade de microfone**. Não
existe equivalente ao `<uses-permission>` do Android; o acesso é decidido em
tempo de execução pelo Windows, em *Configurações → Privacidade e segurança →
Microfone*.

Quando esse acesso está bloqueado, a gravação frequentemente **não lança erro**:
ela roda, grava um WAV bem formado, com a duração correta e amplitude zero. Para
o código, deu tudo certo. No consultório, significa a consulta inteira gravada
muda, descoberta só depois que o paciente foi embora — e a coleta não é
repetível.

O risco está documentado, com o que precisa ser feito, em
[`lib/core/permissions/microphone_permission.dart`](lib/core/permissions/microphone_permission.dart).
**Leia esse arquivo antes de tocar no módulo de captura.** Em resumo: a aferição
de ruído ambiente tem que tratar silêncio absoluto como falha, não como sala
silenciosa, e bloquear a gravação avisando o usuário.

A declaração formal (`<DeviceCapability Name="microphone" />`) só existiria em
pacote MSIX, e o FONAR é distribuído em zip (US41, ver
[Distribuição](#distribuição)): um MSIX só instala assinado por um certificado
em que o computador confia, e o projeto não tem um. O risco continua coberto
pela conferência de silêncio da aferição e de cada gravação.

### A permissão de INTERNET no manifest é declarada à mão. Não remova

O Flutter injeta `android.permission.INTERNET` automaticamente **apenas** nos
manifests de debug e de profile, porque o hot reload precisa dela. No build de
release, essa injeção não acontece.

Como o app fala com a API de análise, a permissão está declarada explicitamente
em `android/app/src/main/AndroidManifest.xml`. Ela parece redundante durante o
desenvolvimento: todo build de debug funciona sem ela. Se alguém "limpar" essa
linha, o app continua perfeito na máquina de quem removeu e chega sem rede na
mão do usuário.

### Credencial no cofre do sistema, e sem backup automático no Android

A credencial do Firebase — o token de acesso, o de renovação e o id da conta,
juntos — fica no cofre do sistema (`flutter_secure_storage`, por
`lib/core/storage/token_storage.dart` e `lib/core/auth/credencial.dart`):
cifrada com chave do Keystore no Android e com chave guardada no Gerenciador
de Credenciais no Windows. Credencial de acesso a dado de saúde não pode ficar
em `SharedPreferences`. O token de acesso vale uma hora e é renovado antes de
vencer (`lib/core/auth/fonte_de_token.dart`), sem pedir a senha; sair da conta
apaga a credencial, e com ela o modo offline daquela conta.

O `AndroidManifest.xml` desliga o backup automático (`allowBackup` e
`dataExtractionRules`). Não reative: o padrão do Android sobe a área privada
do app — banco local e WAV de voz — para o Google Drive da conta do aparelho,
e o token restaurado em outro aparelho não decifra.

### Não instale o Flutter em caminho com espaço, acento ou dentro de Program Files

O SDK do Flutter e a cadeia de build que ele aciona (Gradle, ferramentas do
Android, MSVC) tropeçam em caminhos com espaço ou caractere acentuado, e os
erros que aparecem não têm relação óbvia com a causa.

`C:\Program Files\` acumula os dois problemas: tem espaço no nome e exige
elevação para escrever, o que atrapalha o Flutter ao se atualizar e ao gravar
cache.

Instale em algo curto e sem espaço, como `C:\develop\flutter` (é onde está na
máquina de referência) ou `C:\src\flutter`. Vale também para a pasta onde você
clona este repositório: se o seu usuário do Windows tem acento no nome,
`C:\Users\...` já é um caminho acentuado — clone em outro lugar.

### Os arquivos gerados do Windows aparecem modificados sem você ter mexido

`windows/flutter/generated_plugin_registrant.{cc,h}` e
`windows/flutter/generated_plugins.cmake` são reescritos pela ferramenta do
Flutter a cada build, e estão versionados. Costumam aparecer no `git status` só
por causa de fim de linha. Não edite à mão, e confira o `git diff` antes de
arrastá-los para um commit.
