# FONAR — aplicativo

> [!WARNING]
> **Só existe o esqueleto.** Nenhuma funcionalidade foi implementada. As telas
> estão vazias, não há captura de áudio, não há Firebase, não há chamada de API
> e não há persistência local. O que existe é estrutura de pastas, rotas,
> configuração do Riverpod, cliente HTTP, tema com tokens placeholder e as
> permissões de plataforma. Se você veio procurar a implementação de alguma
> coisa, ela ainda não está aqui.

Aplicativo do FONAR, plataforma de avaliação vocal clínica para
fonoaudiólogos. O uso previsto é durante a consulta, com o paciente presente.

TCC de Engenharia de Software, PUC-Campinas.

**Codebase único para Android e Windows.** Não há funcionalidade exclusiva de
plataforma: as duas rodam exatamente o mesmo conjunto de recursos.

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
| Visual Studio | Build Tools 2026 18.5.11716.220, com Windows 10 SDK 10.0.26100.0 |

O projeto compila para `minSdk 24`, `targetSdk 36` e `compileSdk 36` — valores
herdados do Flutter, não fixados à mão em `android/app/build.gradle.kts`.

### Para build Android

Android Studio, ou o Android SDK sozinho via linha de comando. O JDK embutido no
Android Studio já resolve — não instale outro Java só por causa disto.

### Para build Windows: leia isto antes de tentar

**Você precisa do Visual Studio 2022 ou mais recente com a carga de trabalho
"Desenvolvimento para desktop com C++"** (*Desktop development with C++*).

Este é o passo que mais trava quem chega no projeto, por três motivos:

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

Alternativa mais leve: **Build Tools for Visual Studio**, que é a mesma cadeia
de compilação sem a IDE (é o que está na máquina de referência). Mesma carga
"Desenvolvimento para desktop com C++", download bem menor. Se você não vai
escrever C++, prefira esta.

Confirme com `flutter doctor`: a linha de Visual Studio precisa estar com `[√]`.

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

### Verificar antes de commitar

```bash
dart format .                # o CI reprova código fora do formato padrão
flutter analyze              # precisa terminar com "No issues found!"
flutter test                 # roda a suíte
flutter test test/widget_test.dart                            # um arquivo
flutter test --plain-name "app sobe e abre na rota inicial"   # um teste
```

Mexeu em ícone — adicionou, removeu ou redesenhou um SVG? Rode também
`dart run tool/compilar_icones.dart` e commite o que sair dele. O motivo está
logo abaixo.

### Integração contínua

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) roda a cada push e a
cada pull request, em `ubuntu-latest`, com o mesmo Flutter 3.47.2 da tabela de
pré-requisitos. **Só verifica:** não compila release e não publica nada.

| Passo | Comando |
|---|---|
| Dependências | `flutter pub get` |
| Formatação | `dart format --output=none --set-exit-if-changed .` |
| Análise | `flutter analyze --fatal-infos` |
| Testes | `flutter test` |
| Ícones pré-compilados | `dart run tool/compilar_icones.dart`, e a árvore precisa ficar limpa |

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

Ao subir a versão do Flutter, mude nos dois lugares: na tabela de
pré-requisitos e no `flutter-version` do workflow. Se divergirem, o CI passa a
validar um Flutter que ninguém usa.

### Apontar para a API

A URL da API entra por `--dart-define`, para não versionarmos endpoint no
repositório. O padrão é `http://localhost:8080` (ver
`lib/core/config/app_config.dart`):

```bash
flutter run -d windows --dart-define=FONAR_API_BASE_URL=https://...
```

---

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

### Chrome com `[X]`, e tudo bem

O `flutter doctor` reclama do Chrome ausente porque verifica também o alvo web.
**Web não é alvo deste projeto** — só Android e Windows foram gerados. Pode
ignorar. O que precisa estar verde é Flutter, Android toolchain e Visual Studio.

---

## Estrutura de pastas

```
lib/
├── main.dart              ProviderScope na raiz + FonarApp
├── app/
│   ├── app.dart           MaterialApp.router, tema, sem lógica
│   └── router/            rotas do go_router e constantes de caminho
├── core/                  infraestrutura, sem regra de negócio
│   ├── config/            URL da API e timeouts, via --dart-define
│   ├── error/             AppException selado; erro traduzido para o usuário
│   ├── network/           cliente Dio + interceptors de token e de erro
│   ├── storage/           guarda do token (hoje placeholder)
│   └── permissions/       contrato de permissão de microfone
├── design_system/         tudo que é aparência
│   ├── tokens/            cor, espaçamento, tipografia, raio — placeholders
│   ├── theme/             ThemeData montado a partir dos tokens
│   ├── widgets/           componentes compartilhados
│   └── breakpoints.dart   as faixas de largura (regra 2)
├── l10n/
│   └── app_strings.dart   TODO texto de interface, em pt-BR
└── features/              uma pasta por funcionalidade
    ├── auth/
    ├── pacientes/
    ├── consentimento/
    ├── captura/
    ├── analise/
    └── historico/
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
nem raio de borda: puxam dos tokens. Assim, trocar a identidade visual é
trabalho num lugar só — e hoje os valores são placeholder mesmo, feitos para
serem substituídos.

**`l10n/app_strings.dart`** guarda todo texto visível, incluindo as mensagens de
erro. Dois motivos: revisão da linguagem clínica em um arquivo só, e nenhum
literal solto para caçar depois. Vale a regra de produto — o sistema é
ferramenta de apoio à decisão, **nunca emite diagnóstico**, e nenhum texto pode
sugerir o contrário.

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

A feature branch sai da `main`.

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
pacote MSIX. Empacotamento é decisão de release, ainda em aberto.

### A permissão de INTERNET no manifest é declarada à mão. Não remova

O Flutter injeta `android.permission.INTERNET` automaticamente **apenas** nos
manifests de debug e de profile, porque o hot reload precisa dela. No build de
release, essa injeção não acontece.

Como o app fala com a API de análise, a permissão está declarada explicitamente
em `android/app/src/main/AndroidManifest.xml`. Ela parece redundante durante o
desenvolvimento: todo build de debug funciona sem ela. Se alguém "limpar" essa
linha, o app continua perfeito na máquina de quem removeu e chega sem rede na
mão do usuário.

### `TokenStorageEmMemoria` não serve para build distribuível

`lib/core/storage/token_storage.dart` guarda o token só em memória. É
placeholder, para o esqueleto rodar.

Antes de qualquer build que saia da máquina de desenvolvimento, precisa ser
trocado por armazenamento seguro da plataforma (Keystore no Android, DPAPI no
Windows) ou por obter o token do Firebase Auth sob demanda, sem persistir nada.
Token de acesso a dado de saúde não pode ficar em `SharedPreferences`.

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
