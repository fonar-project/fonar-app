# FONAR — Aplicativo

> Identificadores do projeto: organização GitHub `fonar-project`, repositório
> `fonar-app`, projeto Firebase `fonar-763db`. Pacote Dart `fonar_app`,
> `applicationId` e `namespace` Android `br.com.fonar`, binário Windows
> `fonar_app`, app macOS `FONAR.app` com bundle `br.com.fonar`.
>
> "Praat" e "parselmouth" são o software de análise fonética e seu binding
> Python — nome de terceiro, aparece legitimamente no código e na documentação.
> Não confundir com o nome do projeto.

## Contexto
Aplicativo de avaliação vocal clínica usado por fonoaudiólogos durante a
consulta. Codebase único para Android, Windows, macOS (US41) e navegador (US42,
a versão do iPhone). TCC de Engenharia de Software, PUC-Campinas.

O usuário é profissional de saúde sem formação técnica em computação,
frequentemente com o paciente sentado ao lado e pouco tempo. Em algumas telas
ele vira o aparelho para o paciente ver. A ferramenta que ele usa hoje é o
Praat, software acadêmico de interface dos anos 90. Nosso diferencial é ser
o oposto disso.

## Regra arquitetural inegociável — processamento de áudio
Nenhuma análise acústica ocorre no aplicativo. Toda medida (f0, jitter,
shimmer, HNR, CPPS, AVQI) é calculada no servidor, pela API em Python que usa
o motor do Praat via parselmouth. O app grava, envia e exibe.

Motivo: o parselmouth é GPL v3. Distribuir código GPL dentro de um executável
obriga a abrir todo o projeto. Executar como serviço remoto não caracteriza
distribuição. Esta decisão protege o modelo de negócio, não é preferência.

Decorre daí que **espectrograma e forma de onda chegam como imagem pronta do
servidor**, não são desenhados no cliente.

Única exceção: leitura de amplitude em tempo real para o VU meter e para a
aferição de ruído ambiente, por exigência de latência. Não é medida clínica
e não vai para o laudo.

Nunca adicione biblioteca de DSP, FFT ou análise de áudio ao pubspec.

## Regra arquitetural inegociável — layout
A interface adapta por LARGURA DE TELA, nunca por sistema operacional.

Proibido usar Platform.isAndroid ou Platform.isWindows para decidir layout.
Use LayoutBuilder com breakpoints. Todas as plataformas têm exatamente o mesmo
conjunto de funcionalidades — não existe feature exclusiva de plataforma.

Alvos de design: 1440px e 390px.

Casos que exigem tratamento especial no mobile, e que são de layout e não de
funcionalidade: espectrograma e gráfico de evolução em modo paisagem; escala
CAPE-V em tela cheia dedicada; preview A4 do laudo substituído por resumo
mais ação de baixar ou compartilhar.

## Captura de áudio — módulo de maior risco do projeto
Ao implementar captura, obrigatoriamente:
- Desabilitar ganho automático, supressão de ruído e cancelamento de eco
- Fixar taxa de amostragem, profundidade de bits e número de canais
- Gravar em WAV PCM, sem compressão com perdas
- VERIFICAR empiricamente o que saiu, não confiar na configuração solicitada

Esse processamento automático altera exatamente as propriedades do sinal que
a análise mede. É o requisito que justifica termos app nativo em vez de web.

A versão no navegador (US42) existe só porque não há conta paga da Apple
para instalar app no iPhone, e vem com uma TRAVA: antes de medir o ruído, o
app lê o que o navegador diz ter aplicado à faixa de áudio (`getSettings()`),
e a cada gravação confere de novo pelo aviso do `record`. Processamento
relatado ligado — ou cancelamento de eco não relatado — bloqueia a gravação
e diz o porquê (`naoConfirmadosDesligados`). Não afrouxe essa regra para a
web "funcionar": sem a trava, a versão web não pode gravar.

Risco documentado em `lib/core/permissions/microphone_permission.dart`: no
Windows, app Win32 desempacotado não declara capacidade de microfone, e a
captura pode falhar EM SILÊNCIO — WAV válido, duração certa, amplitude zero,
sem erro. O módulo de captura precisa detectar amplitude zerada na aferição
de ruído e tratar silêncio absoluto como falha, nunca como sala silenciosa.

## Faixas de referência — pendência clínica aberta
Os valores de corte que aparecem no protótipo (AVQI < 2,95, CPPS > 14 dB,
jitter < 1,04%, f0 180–250 Hz, shimmer) **ainda não foram validados por
profissional da área**.

Trate-os como dado configurável vindo de um catálogo, nunca como constante de
interface. Eles variam com sexo, idade e equipamento de captação.

Sempre exista o estado "faixa de referência indisponível para este perfil":
a medida e o valor aparecem, sem classificação de normal ou alterado.
Classificar sem referência válida é pior que não classificar.

Nunca invente referência bibliográfica nem altere os valores.

## Stack
Flutter + Dart. Estado com Riverpod (sem code generation). Rotas com
go_router. HTTP com Dio. Persistência local e fila de sincronização com
Drift. Gráficos com fl_chart. Áudio: record para captura, audioplayers para
reprodução. Ícones com vector_graphics_compiler.
Backend: Firebase (auth e dados) + API Python no Cloud Run (análise).

### Autenticação — Firebase pela API REST, sem `firebase_auth` (US32)
O plugin `firebase_auth` declara o Windows "só para desenvolvimento, produção
não suportada". Como as duas plataformas têm as mesmas funcionalidades, o
login fala com o Identity Toolkit e o Secure Token pela API REST, com o Dio
(`lib/core/auth/`). A chave Web API e a URL da API de produção estão em
`core/config/app_config.dart`: `flutter run` sem nada abre o FONAR de verdade.
Não são segredo (a chave vai dentro de todo app cliente; quem protege os dados
são as regras e a API), e a chave deve ficar restrita ao Identity Toolkit e ao
Token Service (README). O login de EXEMPLO só existe no modo de exemplo
(`--dart-define=FONAR_EXEMPLO=true`), avisado na tela; é o modo dos testes
(`test/flutter_test_config.dart`), e o build `--release` nele se recusa a abrir
(`main.dart`).

- A credencial (token de acesso, de renovação e uid, juntos) fica no cofre
  (`CofreDeCredencial`). A `FonteDeToken` renova ANTES de vencer: a requisição
  recusada não se repete, porque o corpo do envio é um WAV em multipart.
- A sessão é a conta (`sessaoProvider`, `ContaAutenticada`). O roteador manda
  para a entrada quem não tem sessão, sem `refreshListenable` de propósito
  (ver o comentário em `app_router.dart`).
- Cada envio da fila leva o uid de quem gravou e só sobe na sessão dele.
- Não diga se um e-mail tem conta: a redefinição de senha responde igual.
  A exceção inevitável é criar conta (o Firebase recusa e-mail já usado), e
  a mensagem só sugere entrar ou redefinir a senha.
- Criar conta (US34) é do Firebase (`accounts:signUp`, e-mail de
  verificação); o cadastro profissional é da API (`/v1/profissionais/eu`),
  que conduz o primeiro acesso: e-mail por verificar → formulário → entra.
  O credenciamento (pendente ou credenciado) é da equipe, não bloqueia nada,
  e o app só o mostra. `features/cadastro/`.
- Trocar a senha (US45) é na Conta: confere a atual (`signInWithPassword`),
  troca (`accounts:update`), guarda a credencial nova — os tokens de
  renovação de antes deixam de valer — e o verificador da senha sem rede.
  `conta/data/troca_de_senha_firebase.dart`.

### Reprodução de áudio — por que é o `audioplayers` (dívida encerrada)
Até 24/09/2026 a reprodução era `just_audio` + `just_audio_windows`. O plugin
de Windows inclui `<experimental/coroutine>`, header que a Microsoft marcou
como obsoleto e, no MSVC 14.51 (Visual Studio 2026), transformou em erro de
compilação (STL1011). O build do Windows só fechava com o Visual Studio
Community 2022, e o CI teve de ser fixado numa imagem antiga. **Isso acabou**:
o `audioplayers` pede C++20 e não usa o header. O README não exige mais o
Community 2022 e o CI voltou para `windows-latest`.

O critério da escolha não foi a facilidade. O `just_audio_windows_plus` era
drop-in e não custava nenhuma linha de Dart, mas tinha 11 dias de publicação,
2 likes e mantenedor único — o mesmo perfil do plugin que nos deixou na mão.
O `audioplayers_windows` é endossado no pubspec do próprio `audioplayers`
(`default_package`), mantido pela organização que mantém o pacote principal.

**A regra que tornou a troca barata, e que vale manter:** a reprodução está
atrás da interface `Reprodutor` (`features/reproducao/domain/reprodutor.dart`),
e um único arquivo a implementa. Trocar de pacote custou esse arquivo; tela e
controlador não souberam de nada. Nenhuma tela deve importar pacote de áudio
direto.

O `just_audio_media_kit` continua proibido: embute a libmpv, que é GPL, e a
regra de processamento de áudio acima barra GPL dentro do executável.
Reproduzir não é analisar — a troca mexe só em quem toca o WAV, nunca em quem
mede —, mas a restrição de licença vale para o executável inteiro.

Os jobs `build-*` do CI (Windows, Android, macOS e web) são os únicos que
compilam cada plataforma. Teste nenhum pega quebra de compilação delas: a
suíte roda na VM do Dart, no Ubuntu.

## Offline
A fila de sincronização vale para TODAS as plataformas, a web inclusive (o
`web/servico_offline.js` guarda a versão inteira para abrir sem rede). Queda
de conexão em consultório é tão comum quanto ausência de sinal em campo.
Gravação funciona offline; análise exige conexão.

## Design system
Paleta:
- `#FFF7EB` creme — fundo principal
- `#40085E` roxo profundo — primária, botões, header
- `#413C58` cinza chumbo — textos e títulos
- `#DBD2E0` lavanda claro — bordas, cards secundários, divisórias
- `#6E6787` secundário sobre CREME (5,00:1)
- `#5A5472` secundário sobre LAVANDA (4,86:1) — o `#6E6787` sobre lavanda dá
  só 3,62:1 e reprova para texto pequeno. Use o token certo para cada fundo.

Tema escuro (US30, paleta aprovada em 25/09/2026): derivado da marca, sem
matiz novo. Fundo `#17131F`, cartão `#211B2B`, texto `#F1E9DC`, secundário
`#A198B3`. O roxo profundo, que no claro faz botão, texto e barra lateral, no
escuro se divide em três: botão `#6A2F93`, acento (link, ícone, gráfico)
`#D2B0EC`, barra lateral `#260838`. Estados ficam mais claros para passar no
fundo escuro. O profissional escolhe na Conta: do sistema (padrão), claro ou
escuro. O laudo em PDF sai sempre em papel branco.

Nenhum widget usa `AppColors` direto: as cores entram pelo tema, por PAPEL —
`context.cores.fundo`, `.texto`, `.primaria`, `.acento` (ver
`design_system/tokens/app_cores.dart`). Cor nova entra lá, com os dois
valores, e o contraste dos dois temas é conferido em `app_colors_test.dart`.

Verde, amarelo e vermelho são reservados EXCLUSIVAMENTE para status de
normalidade de medida e saturação de áudio. Nunca como decoração.

Exceção: o vermelho é permitido em erro de validação de formulário — borda do
campo, ícone e mensagem. Condição obrigatória: SEMPRE acompanhado de ícone e
de texto dizendo o que corrigir. Vermelho sozinho, ou só a borda colorida, não
atende — quem não distingue a cor fica sem saber que há erro. Verde e amarelo
continuam sem exceção.

Tipografia: Urbanist. Bold para dados e métricas acústicas, Regular para
corpo. Números de medida em fonte tabular.

Acessibilidade: WCAG AA, foco visível, navegação por teclado no desktop.
Nenhuma informação crítica comunicada apenas por cor.

Respeitar `prefers-reduced-motion`: sem transição decorativa, sem animação de
entrada. Exceção proposital — o VU meter continua respondendo ao nível de
áudio, porque é feedback clínico e não decoração; reduza a suavização,
mantenha a resposta.

Fora do movimento reduzido, o movimento é FUNCIONAL (US31): diz o que mudou,
nunca enfeita. Curto (≤ 250 ms), sem quique, zoom ou parallax, e na troca de
conteúdo só o novo entra — o antigo sai na hora, para nunca haver dois
estados (e um valor velho) na tela ao mesmo tempo. Tudo passa pelos tokens e
componentes de `design_system/tokens/app_movimento.dart` (`AppTrocaAnimada`,
`AppRevelar`, `AppTamanhoAnimado`), que já zeram com movimento reduzido.

Ação presa no rodapé só quando cabe: `AppAreaComAcoes` decide pela altura
(já na escala de texto); em tela baixa — celular deitado, texto em 200% —
tudo rola junto. A matriz de layout (`test/app/matriz_de_layout_test.dart`)
varre toda rota do celular pequeno (360×640) ao Full HD, e uma vez com
movimento reduzido.

## Ícones
20 SVG em `assets/icons/`, 24x24, `currentColor`, sem width/height fixos.
Índice de uso em `assets/icons/README.md`.

- Nenhuma tela importa SVG direto. Tudo passa pelo componente único de ícone
- Nomes como enum ou constante, nunca string solta
- **Esta pasta é espelhada com a landing page.** Alteração em um repositório
  exige alteração no outro
- Ícone exportado do Claude Design vem com ~8KB de metadados C2PA que DEVEM
  ser removidos antes de commitar

## Convenções
- `lib/features/<funcionalidade>/` dividido em data, domain e presentation
- Widgets sem lógica de negócio
- Textos de interface em português do Brasil, centralizados em `lib/l10n/`
- Nenhum pacote novo sem justificativa explícita

## Restrições de produto
O sistema é ferramenta de APOIO À DECISÃO. NUNCA emite diagnóstico. Nenhum
texto de interface pode sugerir o contrário.

Áudio de voz vinculado a paciente é dado pessoal sensível pela LGPD. A captura
fica bloqueada enquanto não houver consentimento registrado, e o bloqueio é
técnico — aplicado no roteador — não um aviso na tela.

Decisões jurídicas da US43, todas pelo lado conservador — não afrouxe sem
orientação jurídica: paciente menor de 18 anos só é autorizado pelo
responsável legal; gravação feita sob consentimento retirado não sobe mais,
nem com consentimento novo (o que já foi feito fica como prontuário);
eliminação dos dados só a pedido do paciente, aqui e no servidor; e sem
conexão a senha é conferida por um verificador PBKDF2 no cofre — nunca se
entra nem se desbloqueia sem senha.

Todo dado exibido em desenvolvimento é placeholder e deve ser identificável
como tal.

## Estado atual
O fluxo da avaliação existe de ponta a ponta no aparelho (US00 a US34 — lista
e resumo no README): cadastro, consentimento e retirada, aferição, gravação,
fila, resultado, CAPE-V, evolução, laudo em PDF, com os dados num banco local
(Drift, `lib/core/banco/`).

O login é o Firebase Authentication de verdade (US32). O envio para a análise
é a API de verdade (US33): paciente, consentimentos e sessão sobem para o
Firestore pela API REST (`lib/features/sincronizacao/`), e cada gravação vai
para a API com o id da amostra; o id da análise é o id da sessão. A CAPE-V
registrada também sobe, direto para o Firestore, embaixo da sessão (US37,
ADR-017 da API; `cape_v/data/cape_v_no_firestore.dart`). O laudo emitido
nunca muda nem some: emitir de novo cria outro documento, com número
próprio, que diz qual substitui, e a cópia de cada um sobe para a API como
o PDF saiu (US38, ADR-018 da API; `laudo/data/laudos_na_api.dart`). Os
resultados vêm da API (`RepositorioAnalisesApi`): os valores do motor, sem
classificação enquanto não houver faixa VALIDADA — as faixas provisórias da
API não classificam no app. O CPPS vem da API, da vogal; o AVQI v03.01 também,
da sessão (`resultado_da_sessao`, o script oficial rodado no servidor). O
espectrograma é o PNG da API, buscado com o token (`ImagemDaApi`). Ainda é
PLACEHOLDER, e
identificado como tal, só o modo de exemplo (`AppConfig.exemplo`): o login
que aceita qualquer e-mail e senha, e os resultados e os pacientes "de
Exemplo", que aparecem por cima do banco sem serem gravados nele.

O caminho de volta também existe (US40, `sincronizacao/data/descida_firestore.dart`):
os pacientes da conta e o livro de consentimentos de cada um descem na
abertura, quando a conexão volta e quando alguém entra; CAPE-V e laudos,
quando o perfil do paciente abre; a gravação feita em outro aparelho se ouve
pela API. A descida nunca apaga nem passa por cima de mudança daqui que não
subiu. Cada paciente é de uma conta (`Pacientes.profissionalId`): num
aparelho compartilhado, quem entra só vê os seus, e a fila só mostra os
envios dela.

O app sai para baixar pelo GitHub Releases (US41: Windows, macOS e APK do
Android, sem assinatura de código) e, para o iPhone, como versão web no
GitHub Pages (US42), pelo `release.yml`, a cada tag `v*`. Na web, o banco
local é o SQLite em WebAssembly e os WAV moram nele (`audios_do_navegador`);
tudo o que só o navegador sabe responder passa por `core/navegador/`, com
importação condicional — nenhum outro arquivo importa `package:web`.

O que falta e de quem depende está em `PENDENCIAS.md` — ao resolver um item,
apague a linha de lá e o `TODO` do código, no mesmo commit.

A credencial do Firebase fica no cofre do sistema (`TokenStorageSeguro`, via
`CofreDeCredencial`), e o backup automático do Android está desligado de
propósito — não reativar.

Dados em repouso (US44): no aparelho, o banco local é CIFRADO — SQLite3
Multiple Ciphers, escolhido pelo `hooks` do `pubspec.yaml`, com a chave
aleatória no mesmo cofre (`core/banco/chave_do_banco.dart`). O WAV não é
cifrado, mas só existe até subir: o envio que chega ao servidor o apaga do
aparelho, e ouvir de novo vem da API. Não volte a guardar o WAV depois do
envio, e não troque o `source: sqlite3mc` sem cifrar de outro jeito.

## Git
Branch: `nome/USxx-featureImplementada` — ex.: `felipe/US04-medidorDeNivel`
Commit: Conventional Commits em português, referenciando a User Story:
`feat(US04): adiciona medidor de nivel em tempo real`
Primeiro push vai para a `main`; feature branch sai dela depois.

Sem atribuição de IA em nada que vai para o repositório: nada de
`Co-Authored-By: Claude`, `Claude-Session:`, "Generated with Claude Code" ou
link de sessão em mensagem de commit, descrição de PR ou comentário. O autor
do commit também é a pessoa, nunca `Claude <noreply@anthropic.com>`: antes do
primeiro commit, confira `git config user.name` e `user.email` e use o nome e o
e-mail de quem pediu a alteração, como nos commits anteriores dela.