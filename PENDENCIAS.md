# Pendências abertas

O que ficou em aberto das US02 a US24, reunido num lugar só e organizado por
**quem precisa resolver**. Cada item aponta onde está no código — lá há um
`TODO` com o mesmo assunto, e é lá que a correção acontece.

Ao resolver um item, apague a linha daqui **e** o `TODO` do código, no mesmo
commit.

---

## Orientação clínica

| Pendência | US | Onde |
|---|---|---|
| **Catálogo de faixas de referência validado**, com a fonte de cada faixa. Até lá o app não classifica nenhuma medida — todas aparecem "sem faixa de referência". Os valores do protótipo não foram validados e não estão no código, de propósito. | 07 | `analise/data/catalogo_de_referencias_vazio.dart` |
| Rótulo "Sexo" e as opções do cadastro (inclui "Não informar") servem ao catálogo de faixas? | 02 | `pacientes/domain/novo_paciente.dart` |
| Tarefas de gravação, ordem e instruções ao paciente — hoje provisórias e marcadas assim na tela. | 05 | `captura/domain/amostra.dart`, `l10n/app_strings.dart` |
| Limite de ruído ambiente (−50 dBFS) e zonas do medidor de nível: valores de partida, a calibrar com o equipamento real. | 04 | `captura/domain/afericao_de_ruido.dart`, `captura/domain/nivel_de_audio.dart` |
| Termos da CAPE-V em português (parâmetros, consistência, sentido do desvio, pontas da escala). | 08 | `cape_v/domain/avaliacao_cape_v.dart`, `l10n/app_strings.dart` |
| CAPE-V: exigir o sentido do desvio em pitch e loudness (decisão de implementação). | 08 | `cape_v/domain/avaliacao_cape_v.dart` |
| CAPE-V: esconder o número enquanto se marca, como na folha de papel? | 08 | `cape_v/presentation/pages/cape_v_page.dart` |
| **Limiar de mudança de cada medida** — quanto uma diferença entre sessões precisa ter para contar como mudança. Até lá a evolução mostra os valores lado a lado e não diz que a medida subiu, desceu ou ficou estável. | 09 | `historico/data/limiares_de_mudanca_indefinidos.dart` |
| "Melhorando" / "piorando" na tendência do AVQI (lista) e na evolução. | 01, 09 | `l10n/app_strings.dart` |
| Laudo: quais itens da conferência **impedem** gerar e quais só avisam (hoje impedem consentimento, análise concluída e conclusão escrita; CAPE-V e amostra com problema só avisam). | 10 | `laudo/domain/laudo.dart` |
| Laudo: título, seções e ordem do documento — conferir com o modelo que a orientação espera. | 10 | `laudo/presentation/pdf_do_laudo.dart` |
| Formato do registro no conselho (ex.: "CRFa 2-12345") — hoje só se exige que exista. | 11 | `conta/domain/dados_do_profissional.dart` |
| Modo paciente: o que o paciente vê e com que palavras. Hoje: gráfico da medida escolhida, datas e valores — sem classificação e sem leitura de melhora. | 09 | `l10n/app_strings.dart`, `historico/presentation/pages/evolucao_modo_paciente_page.dart` |

## Orientação jurídica

| Pendência | US | Onde |
|---|---|---|
| **Texto do termo de consentimento** — provisório, marcado na tela. Ao trocar, mudar também a versão do termo. | 03 | `l10n/app_strings.dart`, `consentimento/data/repositorio_consentimento_placeholder.dart` |
| **Desbloqueio sem conexão não confere a senha** — a mesma regra do "entrar em modo offline" do login, que também não confere. Com o Firebase, conferir sem rede por uma credencial local (PIN do app ou biometria do aparelho)? E o modo offline do login, idem. | 24 | `auth/presentation/desbloqueio_controlador.dart` |
| Quando o responsável legal é obrigatório, e se o registro precisa de mais dados dele. | 03 | `consentimento/domain/consentimento.dart` |
| **Sessão de outro dia que ficou pela metade**: desde a US19 o perfil avisa e o profissional ouve, envia ou descarta. Falta decidir se o app apaga sozinho depois de um tempo, e quanto. | 16, 19 | `captura/domain/sessao_nao_enviada.dart` |
| **Depois da retirada do consentimento**: gravações, análises e laudos anteriores continuam no aparelho — apagar? Os envios que estavam na fila param e só sobem se o profissional pedir depois de um consentimento novo — o consentimento novo cobre gravação anterior? O laudo de sessão anterior também fica bloqueado (a conferência exige consentimento em vigor) — é o certo? | 15 | `consentimento/domain/consentimento.dart` (`RetiradaDeConsentimento`) |
| WAV gravados e o banco local ficam sem criptografia na área privada do app: precisa cifrar em repouso? Para o banco há caminho pronto — o mesmo pacote `sqlite3` tem versão com cifra (SQLCipher / SQLite3MultipleCiphers), escolhida na configuração do build. | 05, 14 | `captura/data/gravador_record.dart`, `core/banco/banco_local.dart` |
| **PDF do laudo na pasta temporária**: para compartilhar, o `printing` grava o arquivo na TEMP (no Windows, fica lá depois de aberto). Apagar depois, ou salvar só onde o profissional escolher? | 10 | `laudo/data/saida_do_laudo.dart` |
| **O que fica no aparelho depois de sair da conta** — pacientes, gravações, laudos e fila continuam, agora também depois de fechar o app (banco local), e a fila só sobe quando alguém entrar de novo. | 11, 14 | `l10n/app_strings.dart` (`contaSairTexto`) |
| Gerar o laudo de novo substitui o anterior. Laudo já entregue precisa ficar guardado como foi (versões)? Assinatura digital? | 10 | `laudo/domain/laudo.dart` |

## API de análise (backend)

| Pendência | US | Onde |
|---|---|---|
| **Contrato de envio** — suposto: `POST /analises`, multipart, `Idempotency-Key`. | 06 | `fila/data/envio_de_analise_api.dart` |
| **Contrato do resultado** — `GET /analises/{id}`; para a evolução, `GET /pacientes/{id}/analises`; para o histórico geral, `GET /analises` paginado (hoje ele pergunta paciente por paciente); hoje as telas mostram resultados de exemplo, avisados como tal. | 07, 09 | `analise/data/repositorio_analises_placeholder.dart` |
| Taxa de amostragem e canais que a API espera (hoje 44,1 kHz mono). | 04 | `captura/data/configuracao_de_captura.dart` |
| Quando o aparelho troca taxa ou canais: bloqueia ou só avisa? (hoje só avisa) | 04, 05 | `captura/presentation/pages/captura_page.dart`, `captura/domain/verificacao_da_amostra.dart` |
| Unidade de cada medida (shimmer em % ou dB?). Se a API mandar a unidade, ela prevalece. | 07 | `analise/presentation/apresentacao_da_medida.dart` |
| Contrato de erro da API, para marcar campos recusados. | — | `core/error/app_exception.dart` |

## Equipe (produto e implementação)

| Pendência | US | Onde |
|---|---|---|
| **Numeração das US03 a US10 foi deduzida** das telas do protótipo e do índice de ícones — conferir com o backlog. A US11 (conta) veio do `TODO(US11)` que a equipe deixou no roteador; as US12 (perfil do paciente), US13 (ouvir as gravações), US14 (dados salvos no aparelho), US15 (retirar o consentimento), US16 (retomar a sessão de gravação), US17 (espectrograma no celular), US18 (token no cofre do sistema), US19 (limpeza de gravações não enviadas), US20 (editar os dados do paciente), US21 (aviso de duplicado e de saída sem salvar), US22 (documentação), US23 (histórico geral) e US24 (bloqueio por inatividade) foram escolhidas pelo Felipe. | 03–10 | — |
| **Tempo sem uso até bloquear**: 5 minutos, escolhido sem medir a consulta. O bloqueio também pode cair no meio de uma gravação longa sem toque (a gravação continua embaixo). | 24 | `core/config/app_config.dart` (`tempoDeInatividade`) |
| `TelaPlaceholder` não é mais usada por rota nenhuma — o histórico (US23) era a última tela de andaime. Remover junto com as strings dela e reescrever os testes de convenção que a usam em `app_estrutura_test.dart`. | 23 | `design_system/widgets/tela_placeholder.dart` |
| **Pacientes, consentimentos (e retiradas) e CAPE-V só no aparelho**: estão no banco local, mas ainda não sobem para o Firebase. | 14, 15 | `TODO(backend)` nos repositórios `*_local.dart` |
| **Pacientes e consentimentos de exemplo** aparecem por cima do banco (não são gravados nele). Saem quando a API de análise responder de verdade — os resultados de exemplo são amarrados aos ids deles. | 14 | `pacientes/data/pacientes_de_exemplo.dart`, `consentimento/data/consentimentos_de_exemplo.dart` |
| "Última sessão" e tendência do AVQI do paciente cadastrado: hoje sempre "sem sessão" e "sem comparação" — dependem do contrato do resultado. | 14 | `pacientes/data/repositorio_pacientes_local.dart` |
| Retomar a sessão: só se retoma a do **mesmo dia** (decisão de implementação — a voz muda de um dia para o outro, e a análise combina as tarefas). É isso que define uma consulta? | 16 | `captura/domain/retomada.dart` |
| Cadastro: queixa obrigatória e "salvar leva ao consentimento" foram decisões sem o protótipo. | 02 | `pacientes/presentation/pages/novo_paciente_page.dart` |
| Paciente duplicado: o aviso compara nome e nascimento só com os pacientes **deste aparelho**. Com o Firebase, comparar também com os da conta. | 21 | `pacientes/domain/duplicidade.dart` |
| "Sessão expirada" na fila deve levar ao login (depende do Firebase Auth). | 06 | `fila/presentation/pages/fila_page.dart` |
| **Cada envio da fila levar o id de quem gravou** (uid do Firebase) e só subir na sessão dessa pessoa. Hoje sair pausa a fila e entrar de novo a retoma, mas o placeholder não distingue quem entrou. | 11 | `auth/data/sessao.dart` |
| Espectrograma no laudo: depende do contrato do resultado com a imagem. | 10 | `laudo/presentation/pdf_do_laudo.dart` |
| Se a API exigir o token para servir a imagem do espectrograma, os cabeçalhos entram num lugar só. | 17 | `analise/data/imagem_do_servidor.dart` |
| Ouvir a análise gravada em OUTRO aparelho: hoje só toca o que ainda está neste (achado pelo envio da fila). Precisa da API servir o áudio. | 13 | `fila/presentation/fila_controlador.dart` (`amostrasDaAnaliseProvider`) |
| **WAV sem registro**: se apagar o arquivo antigo falha numa regravação, ou no meio de um descarte já com o registro apagado, o WAV fica no disco sem ninguém que o aponte. Falta uma varredura que compare a pasta de amostras com o banco e apague o que sobrou. | 05, 19 | `captura/presentation/gravacao_controlador.dart` (`_apagarSubstituido`) |
| Descartar uma sessão confere se ela já está num envio antes de apagar qualquer arquivo, mas conferência e descarte não são uma operação só: um envio criado exatamente entre os dois ainda perderia o WAV. Hoje nenhum fluxo põe na fila a sessão que está na tela de limpeza; se passar a existir, os dois precisam de trava comum. | 19 | `captura/presentation/gravacoes_nao_enviadas_controlador.dart` |
| Consentimento vigente: no aparelho, vale a ordem de gravação (id autoincremento), não o relógio. Ao sincronizar com o Firebase, a ordem entre aparelhos precisa de regra própria. | 14, 15 | `consentimento/data/repositorio_consentimento_local.dart` |

## Verificar em aparelho real

Nada abaixo foi testado com hardware: o ambiente em que o código foi escrito
não tem microfone. Os testes automatizados cobrem a lógica com microfone e
rede simulados.

| O que conferir | US | Onde |
|---|---|---|
| **Microfone bloqueado pela privacidade do Windows**: a aferição precisa acusar "microfone não está captando som". | 04 | `captura/data/fonte_de_nivel_record.dart` |
| Nível do medidor e aferição no Android e no Windows, com o microfone do projeto. | 04 | idem |
| O WAV gravado sai PCM 16 bits, 44,1 kHz, mono — e a conferência aceita. | 05 | `captura/data/gravador_record.dart` |
| Se o `setOnConfigChanged` avisa quando o aparelho troca a taxa. | 04 | `captura/data/fonte_de_nivel_record.dart` |
| Fila: desligar a rede, mandar uma gravação, religar — ela sobe sozinha? | 06 | `fila/presentation/fila_controlador.dart` |
| Sair da conta com um envio no ar: o upload é mesmo interrompido (CancelToken do Dio) e o item volta para a fila? | 11 | `fila/data/envio_de_analise_api.dart` |
| **Banco local no Android e no Windows**: cadastrar, fechar o app de verdade e abrir de novo — o paciente, o consentimento e a fila continuam lá? O arquivo fica na área privada (`getApplicationSupportDirectory`), e não em "Documentos". | 14 | `core/banco/banco_local.dart` |
| O build baixa o SQLite pronto (conferido por SHA-256) na primeira compilação de cada plataforma: precisa de rede nessa hora. | 14 | `pubspec.yaml` (`drift_flutter`) |
| Espectrograma em tela cheia: girar o celular, pinça e arrastar no Android; roda do mouse, arrastar e teclado (setas, + e −) no Windows. | 17 | `analise/presentation/pages/espectrograma_page.dart` |
| **Token no cofre do sistema**: guardar, fechar o app e abrir de novo no Android e no Windows. E, no Android, confirmar que o backup automático está mesmo desligado (Configurações → Sistema → Backup não lista o FONAR). | 18 | `core/storage/token_storage.dart`, `AndroidManifest.xml` |
| **Bloqueio por inatividade**: deixar o app em segundo plano mais de 5 minutos e voltar — bloqueia na hora? No Windows, digitar conta como uso? | 24 | `auth/presentation/widgets/vigia_de_inatividade.dart` |
| Ouvir as gravações no Android e no Windows — no Windows, o `just_audio_windows` precisa compilar e tocar o WAV da área privada. | 13 | `reproducao/data/reprodutor_just_audio.dart` |
| Falha no meio da reprodução (desconectar o fone, arquivo corrompido depois do cabeçalho): o player sai de "tocando" e mostra a falha? Os testes simulam o erro; o caminho do `just_audio` não foi exercitado. | 13 | `reproducao/data/reprodutor_just_audio.dart` |
| Laudo: "abrir ou compartilhar" e "imprimir ou salvar" no Android e no Windows, e a pré-visualização A4 no Windows (o `printing` baixa o pdfium no build). | 10 | `laudo/data/saida_do_laudo.dart`, `laudo/presentation/laudo_controlador.dart` |

## Já existiam antes da US02

Continuam valendo, com `TODO` no código: autenticação com Firebase (redirect
de login, sessão, modo offline — e, desde a US11, o perfil do profissional e
o sair da conta),
recuperação e troca de senha, tema escuro, tela de erro própria do roteador.
