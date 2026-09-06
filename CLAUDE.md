# Praatico — Aplicativo

## Contexto
Aplicativo de avaliação vocal clínica usado por fonoaudiólogos durante a
consulta. Codebase único para Android e Windows. TCC de Engenharia de
Software, PUC-Campinas.

O usuário é profissional de saúde sem formação técnica em computação,
frequentemente com o paciente ao lado e pouco tempo. A ferramenta que ele
usa hoje é o Praat, um software acadêmico de interface dos anos 90. Nosso
diferencial é ser o oposto disso.

## Regra arquitetural inegociável — processamento de áudio
Nenhuma análise acústica ocorre no aplicativo. Toda medida (f0, jitter,
shimmer, HNR, CPPS, AVQI) é calculada no servidor, pela API em Python que
usa o motor do Praat via parselmouth. O app grava, envia e exibe.

Motivo: o parselmouth é licenciado sob GPL v3. Distribuir código GPL dentro
de um executável obriga a abrir todo o projeto. Executar como serviço remoto
não caracteriza distribuição. Esta decisão protege o modelo de negócio, não
é preferência técnica.

Única exceção: leitura de amplitude em tempo real para alimentar o medidor
de nível visual e a aferição de ruído ambiente, por exigência de latência.
Isso não é medida clínica e não vai para o laudo.

Nunca adicione biblioteca de DSP, FFT ou análise de áudio ao pubspec.

## Regra arquitetural inegociável — layout
A interface adapta por LARGURA DE TELA, nunca por sistema operacional.

Proibido usar Platform.isAndroid ou Platform.isWindows para decidir layout.
Use LayoutBuilder com breakpoints. Android e Windows têm exatamente o mesmo
conjunto de funcionalidades — não existe funcionalidade exclusiva de
plataforma neste projeto.

## Captura de áudio — módulo de maior risco do projeto
Ao implementar captura, obrigatoriamente:
- Desabilitar ganho automático, supressão de ruído e cancelamento de eco
- Fixar taxa de amostragem, profundidade de bits e número de canais
- Gravar em WAV PCM, sem compressão com perdas
- VERIFICAR empiricamente o que saiu, não confiar na configuração solicitada

Esse processamento automático altera exatamente as propriedades do sinal que
a análise mede. É o requisito que justifica termos aplicativo nativo em vez
de web.

## Stack
Flutter + Dart. Estado com Riverpod. HTTP com Dio. Persistência local e fila
de sincronização com Drift. Gráficos com fl_chart. Áudio: record para
captura, just_audio para reprodução.
Backend: Firebase (auth e dados) + API Python no Cloud Run (análise).

## Convenções
- `lib/features/<funcionalidade>/` dividido em data, domain e presentation
- Widgets sem lógica de negócio
- Textos de interface em português do Brasil, centralizados em um arquivo
- Nenhum pacote novo sem justificativa explícita
- Acessibilidade: contraste AA, foco visível. Nenhuma informação crítica
  comunicada apenas por cor

## Restrições de produto
O sistema é ferramenta de apoio à decisão clínica. NUNCA emite diagnóstico.
Nenhum texto de interface pode sugerir o contrário.

Áudio de voz vinculado a paciente é dado pessoal sensível pela LGPD. A
captura fica bloqueada enquanto não houver consentimento registrado, e o
bloqueio é técnico, não um aviso na tela.

## Estado atual
Apenas o scaffold do `flutter create`. Nenhuma feature implementada.

## Git
Branch: `nome/USxx-featureImplementada` — ex.: `felipe/US04-medidorDeNivel`
Commit: Conventional Commits em português, referenciando a User Story:
`feat(US04): adiciona medidor de nivel em tempo real`
Primeiro push vai para a `main`; feature branch sai dela depois.