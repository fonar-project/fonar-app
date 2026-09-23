# Pendências abertas

O que ficou em aberto das US02 a US09, reunido num lugar só e organizado por
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
| Modo paciente: o que o paciente vê e com que palavras. Hoje: gráfico da medida escolhida, datas e valores — sem classificação e sem leitura de melhora. | 09 | `l10n/app_strings.dart`, `historico/presentation/pages/evolucao_modo_paciente_page.dart` |

## Orientação jurídica

| Pendência | US | Onde |
|---|---|---|
| **Texto do termo de consentimento** — provisório, marcado na tela. Ao trocar, mudar também a versão do termo. | 03 | `l10n/app_strings.dart`, `consentimento/data/repositorio_consentimento_placeholder.dart` |
| Quando o responsável legal é obrigatório, e se o registro precisa de mais dados dele. | 03 | `consentimento/domain/consentimento.dart` |
| WAV gravados ficam sem criptografia na área privada do app: precisa cifrar em repouso? | 05 | `captura/data/gravador_record.dart` |

## API de análise (backend)

| Pendência | US | Onde |
|---|---|---|
| **Contrato de envio** — suposto: `POST /analises`, multipart, `Idempotency-Key`. | 06 | `fila/data/envio_de_analise_api.dart` |
| **Contrato do resultado** — `GET /analises/{id}` e, para a evolução, `GET /pacientes/{id}/analises`; hoje as telas mostram resultados de exemplo, avisados como tal. | 07, 09 | `analise/data/repositorio_analises_placeholder.dart` |
| Taxa de amostragem e canais que a API espera (hoje 44,1 kHz mono). | 04 | `captura/data/configuracao_de_captura.dart` |
| Quando o aparelho troca taxa ou canais: bloqueia ou só avisa? (hoje só avisa) | 04, 05 | `captura/presentation/pages/captura_page.dart`, `captura/domain/verificacao_da_amostra.dart` |
| Unidade de cada medida (shimmer em % ou dB?). Se a API mandar a unidade, ela prevalece. | 07 | `analise/presentation/apresentacao_da_medida.dart` |
| Contrato de erro da API, para marcar campos recusados. | — | `core/error/app_exception.dart` |

## Equipe (produto e implementação)

| Pendência | US | Onde |
|---|---|---|
| **Numeração das US03 a US09 foi deduzida** das telas do protótipo e do índice de ícones — conferir com o backlog. | 03–09 | — |
| **Drift**: pacientes, consentimentos, gravações, fila e CAPE-V estão em memória e somem ao fechar o app. Decisão registrada: entra numa US própria, trocando só os repositórios. | 06 | todos os `TODO(drift)` |
| Retomar a sessão de gravação em andamento ao voltar para a tela (hoje abre outra, e as gravações da anterior ficam órfãs no disco). | 05 | `captura/presentation/gravacao_controlador.dart` |
| Retirada do consentimento: o termo promete, o app ainda não tem. | 03 | `consentimento/domain/consentimento.dart` |
| Cadastro: queixa obrigatória e "salvar leva ao consentimento" foram decisões sem o protótipo. Faltam aviso de paciente duplicado e aviso ao sair com o formulário preenchido. | 02 | `pacientes/presentation/pages/novo_paciente_page.dart` |
| Tela 02 do protótipo parece ser o **perfil do paciente** (com a situação do consentimento), ainda placeholder. Hoje a evolução só é alcançada pelo resultado de uma análise; o perfil deve levar a ela também. | 02, 09 | `pacientes/presentation/pages/paciente_detalhe_page.dart` |
| Espectrograma em modo paisagem, tela cheia, no celular. | 07 | `analise/presentation/pages/analise_resultado_page.dart` |
| "Sessão expirada" na fila deve levar ao login (depende do Firebase Auth). | 06 | `fila/presentation/pages/fila_page.dart` |
| README e a seção "Estado atual" do CLAUDE.md ainda dizem que só existe o esqueleto. | — | `README.md`, `CLAUDE.md` |

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

## Já existiam antes da US02

Continuam valendo, com `TODO` no código: autenticação com Firebase (redirect
de login, sessão, modo offline), `TokenStorageEmMemoria` fora de build
distribuível, recuperação de senha, tema escuro, tela de erro própria do
roteador, conta do profissional, histórico.
