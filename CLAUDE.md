# FONAR — Aplicativo

> Identificadores do projeto: organização GitHub `fonar-project`, repositório
> `fonar-app`, projeto Firebase `fonar-763db`. Pacote Dart `fonar_app`,
> `applicationId` e `namespace` Android `br.com.fonar`, binário Windows
> `fonar_app`.
>
> "Praat" e "parselmouth" são o software de análise fonética e seu binding
> Python — nome de terceiro, aparece legitimamente no código e na documentação.
> Não confundir com o nome do projeto.

## Contexto
Aplicativo de avaliação vocal clínica usado por fonoaudiólogos durante a
consulta. Codebase único para Android e Windows. TCC de Engenharia de
Software, PUC-Campinas.

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
Use LayoutBuilder com breakpoints. Android e Windows têm exatamente o mesmo
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
Drift. Gráficos com fl_chart. Áudio: record para captura, just_audio para
reprodução. Ícones com vector_graphics_compiler.
Backend: Firebase (auth e dados) + API Python no Cloud Run (análise).

## Offline
A fila de sincronização vale para AS DUAS plataformas. Queda de conexão em
consultório é tão comum quanto ausência de sinal em campo. Gravação funciona
offline; análise exige conexão.

## Design system
Paleta:
- `#FFF7EB` creme — fundo principal
- `#40085E` roxo profundo — primária, botões, header
- `#413C58` cinza chumbo — textos e títulos
- `#DBD2E0` lavanda claro — bordas, cards secundários, divisórias
- `#6E6787` secundário sobre CREME (5,00:1)
- `#5A5472` secundário sobre LAVANDA (4,86:1) — o `#6E6787` sobre lavanda dá
  só 3,62:1 e reprova para texto pequeno. Use o token certo para cada fundo.

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

## Ícones
19 SVG em `assets/icons/`, 24x24, `currentColor`, sem width/height fixos.
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

Todo dado exibido em desenvolvimento é placeholder e deve ser identificável
como tal.

## Estado atual
Esqueleto: rotas, tema, tokens, camada de rede e permissões. Nenhuma feature
implementada. O token de autenticação fica no cofre do sistema
(`TokenStorageSeguro`), e o backup automático do Android está desligado de
propósito — não reativar.

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