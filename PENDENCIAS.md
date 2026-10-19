# Pendências abertas

O que ficou em aberto das US02 a US24, reunido num lugar só e organizado por
**quem precisa resolver**. Cada item aponta onde está no código — quase sempre
há um `TODO` com o mesmo assunto, e é lá que a correção acontece. Onde não há
`TODO`, a própria linha explica por quê.

Ao resolver um item, apague a linha daqui **e** o `TODO` do código, quando
houver, no mesmo commit.

---

## Orientação clínica

| Pendência | US | Onde |
|---|---|---|
| **Catálogo de faixas de referência validado**, com a fonte de cada faixa. Até lá o app não classifica nenhuma medida — todas aparecem "sem faixa de referência". Os valores do protótipo não foram validados e não estão no código, de propósito. | 07 | `analise/data/catalogo_de_referencias_vazio.dart` |
| Rótulo "Sexo" e as opções do cadastro (inclui "Não informar") servem ao catálogo de faixas? | 02 | `pacientes/domain/novo_paciente.dart` |
| Tarefas de gravação, ordem e instruções ao paciente — hoje provisórias e marcadas assim na tela. A fala encadeada já é a contagem de 1 a 20 da validação brasileira do AVQI (item 7 das pendências clínicas da API); falta validar o texto dito ao paciente e se a contagem é de 1 a 20 (AVQI) ou de 1 a 11 (ABI). | 05, 36 | `captura/domain/amostra.dart`, `l10n/app_strings.dart` |
| Limite de ruído ambiente (−50 dBFS) e zonas do medidor de nível: valores de partida, a calibrar com o equipamento real. | 04 | `captura/domain/afericao_de_ruido.dart`, `captura/domain/nivel_de_audio.dart` |
| Termos da CAPE-V em português (parâmetros, consistência, sentido do desvio, pontas da escala). | 08 | `cape_v/domain/avaliacao_cape_v.dart`, `l10n/app_strings.dart` |
| CAPE-V: exigir o sentido do desvio em pitch e loudness (decisão de implementação). | 08 | `cape_v/domain/avaliacao_cape_v.dart` |
| CAPE-V: esconder o número enquanto se marca, como na folha de papel? | 08 | `cape_v/presentation/pages/cape_v_page.dart` |
| CAPE-V: âncoras "leve", "moderado" e "severo" sob a régua, como no protótipo — onde ficam na linha e com que termos. Até lá a régua só tem os números. | 28 | `cape_v/presentation/pages/cape_v_page.dart` |
| CAPE-V: mostrar o espectrograma ao lado da régua? Antes ou só depois de marcar? A CAPE-V é julgamento pelo ouvido, e ver a imagem pode enviesá-lo — a mesma família de "esconder o número". Até lá a tela não mostra o espectrograma. Se aprovado: painel ao lado no desktop (talvez revelado só depois de registrar), botão no celular, com o `ImagemDaApi`. | 52 | `cape_v/presentation/pages/cape_v_page.dart` |
| **Limiar de mudança de cada medida** — quanto uma diferença entre sessões precisa ter para contar como mudança. Até lá a evolução mostra os valores lado a lado e não diz que a medida subiu, desceu ou ficou estável. | 09 | `historico/data/limiares_de_mudanca_indefinidos.dart` |
| "Melhorando" / "piorando" na tendência do AVQI (lista) e na evolução. | 01, 09 | `l10n/app_strings.dart` |
| Laudo: quais itens da conferência **impedem** gerar e quais só avisam (hoje impedem consentimento, análise concluída e conclusão escrita; CAPE-V e amostra com problema só avisam). | 10 | `laudo/domain/laudo.dart` |
| Laudo: título, seções e ordem do documento — conferir com o modelo que a orientação espera. | 10 | `laudo/presentation/pdf_do_laudo.dart` |
| Formato do registro no conselho: com a API, desde a US34, é região do Crefono (1ª a 9ª) + número, e a Conta só aceita "CRFa 2-12345". Sem a API, segue texto livre. O número tem dígito verificador, letras, outro formato em alguma região? | 11, 34 | `conta/domain/dados_do_profissional.dart`, `cadastro/domain/cadastro.dart` |
| Modo paciente: o que o paciente vê e com que palavras. Hoje: gráfico da medida escolhida, datas e valores — sem classificação e sem leitura de melhora. | 09 | `l10n/app_strings.dart`, `historico/presentation/pages/evolucao_modo_paciente_page.dart` |

## Orientação jurídica

| Pendência | US | Onde |
|---|---|---|
| **Revisão jurídica dos textos** (US43): o termo de consentimento e os termos de uso e a política de privacidade foram escritos sobre a LGPD (dado de saúde, art. 11; transferência internacional, art. 33; direitos, art. 18; retirada, art. 8º) e as decisões conservadoras deste projeto, mas não passaram por advogado. Revisar antes do uso com pacientes reais; mudar o texto exige mudar a versão (`versaoAtualDoTermo`, `versaoDosTermos`). Falta também um canal de contato da equipe para os profissionais (e-mail) — acrescentar aos termos quando existir. | 03, 34, 43 | `l10n/app_strings.dart` |
| **Pendente pode gravar paciente?** Hoje sim: o cadastro aberto deixa usar tudo enquanto a equipe confere a inscrição no Crefono (decisão do time, ADR-015 da API). Se o pendente tiver de esperar, a troca é na API. | 34 | — |
| **Anotação não se apaga** (US51): é prontuário, e só sai com a eliminação do paciente, a pedido dele; editar guarda a versão de antes. Não depende do consentimento, que cobre a voz. Decisões do Matheus em 15/10/2026, pelo lado conservador; se a orientação jurídica pedir apagar (uma anotação escrita no paciente errado, por exemplo), a regra muda no `firestore.rules` da API (ADR-019) e aqui. | 51 | `anotacoes/data/repositorio_anotacoes_local.dart` |
| **Sessão de outro dia que ficou pela metade**: desde a US19 o perfil avisa e o profissional ouve, envia ou descarta. Falta decidir se o app apaga sozinho depois de um tempo, e quanto. | 16, 19 | `captura/domain/sessao_nao_enviada.dart` |

## Equipe (produto e implementação)

| Pendência | US | Onde |
|---|---|---|
| **Numeração das US03 a US10 foi deduzida** das telas do protótipo e do índice de ícones — conferir com o backlog. A US11 (conta) veio do `TODO(US11)` que a equipe deixou no roteador; as US12 (perfil do paciente), US13 (ouvir as gravações), US14 (dados salvos no aparelho), US15 (retirar o consentimento), US16 (retomar a sessão de gravação), US17 (espectrograma no celular), US18 (token no cofre do sistema), US19 (limpeza de gravações não enviadas), US20 (editar os dados do paciente), US21 (aviso de duplicado e de saída sem salvar), US22 (documentação), US23 (histórico geral) e US24 (bloqueio por inatividade) foram escolhidas pelo Felipe. | 03–10 | — |
| **Pacientes, consentimentos e resultados de exemplo** aparecem só no modo de exemplo (`--dart-define=FONAR_EXEMPLO=true`, o dos testes; avisados na tela); o app normal abre na API (US33). Apagar de vez quando ninguém mais precisar deles para olhar as telas sem servidor. | 14, 33 | `core/config/app_config.dart` (`exemplo`) |
| Tendência do AVQI do paciente cadastrado, na lista: hoje sempre "sem comparação". Depende do limiar de mudança (ver "Orientação clínica"); com ele, a lista ainda precisa ler as análises da API (`compararUltimas` já faz a conta), porque hoje ela lê só o banco local. A "última sessão" já aparece: é a gravação mais nova do paciente neste aparelho. | 14 | `pacientes/data/repositorio_pacientes_local.dart` |

## Verificar em aparelho real

Nada abaixo foi testado com hardware: o ambiente em que o código foi escrito
não tem microfone. Os testes automatizados cobrem a lógica com microfone e
rede simulados.

| O que conferir | US | Onde |
|---|---|---|
| **macOS** (US41): abrir pela primeira vez (Ajustes → Privacidade e Segurança → Abrir Mesmo Assim), o pedido de microfone, gravar, entrar e reabrir (o cofre no keychain comum), salvar e imprimir o laudo. Nada disso rodou num Mac: o CI só compila. | 41 | `macos/Runner/`, `core/storage/token_storage.dart` |
| **Versão web no iPhone** (US42), no Safari e pela Tela de Início: (1) a trava — o Safari relata `echoCancellation: false` com o pedido da captura e não relata ganho nem supressão, que no WebKit fazem parte do mesmo processamento de voz; se relatar outra coisa, ou se o som sair processado mesmo assim, a regra de `naoConfirmadosDesligados` precisa endurecer; (2) o WAV sai PCM 16 bits, 44,1 kHz, mono; (3) ouvir a gravação; (4) abrir sem internet depois da primeira vez; (5) os dados continuam lá dias depois; (6) o laudo baixa e compartilha. Nada disso rodou num iPhone: o CI só compila. | 42 | `core/navegador/navegador_web.dart`, `captura/domain/processamento_automatico.dart`, `web/servico_offline.js` |
| **Banco cifrado** (US44) no Android, no Windows e no macOS: o app abre, guarda e reabre; um banco de antes da atualização é cifrado na primeira abertura e continua com tudo. O CI compila e os testes da cifra rodam no Linux, com o mesmo SQLite3 Multiple Ciphers; nas outras plataformas, só no aparelho. | 44 | `core/banco/banco_local.dart`, `core/banco/cifra_do_banco_nativa.dart` |
| **APK de release** instalado num celular: a chave de release, a atualização por cima de uma versão anterior. | 41 | `android/app/build.gradle.kts`, `.github/workflows/release.yml` |
| **Microfone bloqueado pela privacidade do Windows**: a aferição precisa dar "Não chegou som nenhum" e, depois da conferência com a voz, "O microfone não está captando som". | 04 | `captura/data/fonte_de_nivel_record.dart` |
| **Escolha do microfone** (teste de homologação de 18/10/2026): no Windows com o DroidCam instalado, a lista mostra o microfone de verdade e o virtual, e gravar pelo de verdade funciona; o escolhido continua valendo depois de fechar e abrir o app; desconectado, a tela avisa e grava pelo padrão. Conferir também no Android (fone com fio), no macOS e no navegador. O `record` aceita o aparelho em todas, mas nada disso rodou com microfone. | 04 | `captura/data/microfones_record.dart` |
| **Sala em silêncio total** (teste de homologação de 18/10/2026): o microfone que zera o sinal sem som dá "Não chegou som nenhum"; falar na conferência com a voz libera em cerca de 1 s ("Sala silenciosa e microfone captando"); e a contagem de 1 a 20, que começa em silêncio, passa na conferência do arquivo. | 04, 05 | `captura/domain/afericao_de_ruido.dart`, `captura/domain/verificacao_da_amostra.dart` |
| **Desligar o processamento automático é PEDIDO, não garantia.** O `RecordConfig` manda `autoGain: false`, `noiseSuppress: false` e `echoCancel: false`, e no Android a fonte `VOICE_RECOGNITION` — que a definição de compatibilidade obriga a chegar sem ganho automático nem redução de ruído. Nada disso é CONFIRMADO em tempo de execução: o `record` não devolve o que a plataforma aceitou, e o cabeçalho do WAV cobre formato (taxa, canais, bits), não processamento. Um fabricante que ignore o pedido altera exatamente as propriedades que a análise mede, e o app não tem como perceber. Só se confirma medindo em aparelho real — gravar o mesmo sinal conhecido em cada aparelho e comparar. (No navegador, US42, há confirmação: o navegador relata o que aplicou, e a gravação trava se algo ficou ligado.) | 04, 05 | `captura/data/configuracao_de_captura.dart` |
| Nível do medidor e aferição no Android e no Windows, com o microfone do projeto. | 04 | idem |
| O WAV gravado sai PCM 16 bits, 44,1 kHz, mono — e a conferência aceita. A profundidade de bits é a única parte do formato que não se PEDE: vem embutida no encoder `wav`, e nem o `setOnConfigChanged` fala dela. A conferência compara o cabeçalho com `ConfiguracaoDeCaptura.bitsPorAmostra`, que é suposição sobre o encoder — o cabeçalho é a única evidência que existe. | 05 | `captura/data/gravador_record.dart`, `captura/data/configuracao_de_captura.dart` |
| Se o `setOnConfigChanged` avisa quando o aparelho troca a taxa. Desde 25/09/2026 ele é registrado nas DUAS capturas — a da aferição e a da gravação —, e na gravação o aviso já gera ressalva de formato por si, mesmo que o cabeçalho repita o que foi pedido. Nunca foi visto disparar. | 04, 05 | `captura/data/fonte_de_nivel_record.dart`, `captura/data/gravador_record.dart` |
| Fila: desligar a rede, mandar uma gravação, religar — ela sobe sozinha? | 06 | `fila/presentation/fila_controlador.dart` |
| Sair da conta com um envio no ar: o upload é mesmo interrompido (CancelToken do Dio) e o item volta para a fila? | 11 | `fila/data/envio_de_analise_api.dart` |
| **Banco local no Android e no Windows**: cadastrar, fechar o app de verdade e abrir de novo — o paciente, o consentimento e a fila continuam lá? O arquivo fica na área privada (`getApplicationSupportDirectory`), e não em "Documentos". | 14 | `core/banco/banco_local.dart` |
| O build baixa o SQLite pronto (conferido por SHA-256) na primeira compilação de cada plataforma: precisa de rede nessa hora. | 14 | `pubspec.yaml` (`drift_flutter`) |
| **Anotações em dois aparelhos** (US51): escrever sem rede, a rede voltar e a anotação subir; abrir o perfil no outro aparelho e ela descer; ver o lembrete num e ele sumir no outro. Os testes simulam o Firestore; as regras de verdade só valem depois do `firebase deploy --only firestore` (PR da API). | 51 | `anotacoes/data/anotacoes_no_firestore.dart` |
| **Guia da primeira vez e dicas por tela** (US50) com leitor de tela — NVDA no Windows, TalkBack no Android: cada passo (e cada dica) é anunciado com o texto, o foco fica no balão e o Esc (ou o voltar) fecha. Os testes conferem o anúncio e o foco na VM do Dart; o leitor de verdade, só no aparelho. | 50 | `guia/presentation/widgets/guia_na_tela.dart` |
| Espectrograma em tela cheia: girar o celular, pinça e arrastar no Android; roda do mouse, arrastar e teclado (setas, + e −) no Windows. | 17 | `analise/presentation/pages/espectrograma_page.dart` |
| **Credencial no cofre do sistema**: entrar, fechar o app e abrir de novo no Android e no Windows — o modo offline oferece a conta? E, no Android, confirmar que o backup automático está mesmo desligado (Configurações → Sistema → Backup não lista o FONAR). | 18, 32 | `core/storage/token_storage.dart`, `AndroidManifest.xml` |
| **Login com o Firebase de verdade**, com a chave do projeto: entrar; errar a senha; errar várias vezes (a conta pausa); "Esqueci a senha" — o e-mail chega, em português? Deixar a fila enviando por mais de uma hora: o token é renovado sem pedir a senha? Trocar a senha no console com o app aberto: a fila passa a pedir "Entrar de novo"? Trocar a senha pela Conta (US45): neste aparelho a fila segue sem pedir nada, e no outro pede "Entrar de novo"? Nada disso rodou contra o Firebase: os testes simulam as respostas da API REST. | 32, 45 | `core/auth/firebase_auth_rest.dart`, `core/auth/fonte_de_token.dart`, `conta/data/troca_de_senha_firebase.dart` |
| **Manter conectado** (US59): entrar com a caixa marcada, fechar o app de vez e abrir de novo no Android, no Windows, no macOS e na versão web — abre direto nos pacientes, sem a entrada piscar? Sair da conta e abrir de novo: pede a senha? Os testes conferem com um cofre em memória; o cofre de verdade de cada sistema, só no aparelho. | 59 | `auth/data/sessao_mantida.dart`, `main.dart` |
| Ouvir as gravações no **Android**. No Windows já foi conferido em 24/09/2026, com o `audioplayers` tocando um WAV da área privada do app. | 13 | `reproducao/data/reprodutor_audioplayers.dart` |
| Falha no meio da reprodução (desconectar o fone, arquivo corrompido depois do cabeçalho): o player sai de "tocando" e mostra a falha? Os testes simulam o erro; o caminho real, o `eventStream` do `audioplayers` levando o erro a `falhas`, não foi exercitado. | 13 | `reproducao/data/reprodutor_audioplayers.dart` |
| Laudo: "salvar ou compartilhar" (no Windows, o "Salvar como" do `file_selector`; no Android, a folha do sistema, com o PDF apagado do cache na abertura seguinte) e "imprimir ou salvar", e a pré-visualização A4 no Windows (o `printing` baixa o pdfium no build). | 10, 38 | `laudo/data/saida_do_laudo.dart`, `laudo/presentation/laudo_controlador.dart` |
