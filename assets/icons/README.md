# Ícones FONAR — SVG

24×24 · `currentColor` (a cor vem do código que os usa) · sem largura/altura fixas.
Não há ilustrações vetoriais no design system: espectrograma e formas de onda do protótipo são renderizados por CSS/dados, não assets.

| Arquivo | Onde é usado (telas) |
|---|---|
| `confirmacao.svg` | qualidade boa (02, 05, 07), consentimento registrado (02, 03), passos concluídos (06), checklist do laudo (10, 11) |
| `alerta.svg` | credencial inválida (00), amostra com problema (02, 05, 07), falha de envio (06), fora da faixa (07, 09, 10) |
| `negacao.svg` | consentimento não registrado (02, 03) |
| `gravar.svg` | iniciar gravação (03, 04), passo atual da fila (06) |
| `reproduzir.svg` | players de amostra (04, 05, 07) |
| `pausar.svg` | players de amostra (04, 05, 07) |
| `sem-referencia.svg` | medida sem faixa de referência (07, 09, 10, 11) |
| `tendencia-melhora.svg` | chip de tendência AVQI ↗ (01) |
| `tendencia-estavel.svg` | chip de tendência AVQI → (01) |
| `tendencia-piora.svg` | chip de tendência AVQI ↘ (01) |
| `voltar.svg` | cabeçalho mobile ‹ (02, 03, 05, 06, 07, 10, 11) |
| `avancar.svg` | linhas de lista e CTAs › (01, 02, 05, 06, 07, 09, 10) |
| `adicionar.svg` | nova avaliação ＋ (01, 02) |
| `informacao.svg` | procedência da faixa de referência (07, 09) |
| `virar-para-paciente.svg` | modo paciente ⟳ (09) |
| `girar-aparelho.svg` | dica de paisagem p/ espectrograma ⟲ (07 mobile) |
| `passo-pendente.svg` | passo aguardando na fila (06) |
| `estado-online.svg` | indicador de conexão ativo (00, 01, 06, 11) |
| `estado-sem-conexao.svg` | indicador sem conexão (00, 06) |

---

## Antes de commitar ícone novo: remova os metadados C2PA

Ícone exportado do **Claude Design** vem com cerca de **8 KB de metadados de
procedência C2PA** embutidos no SVG — um bloco `<metadata>` que não desenha
nada. Em 19 ícones isso é mais de 150 KB de lixo no repositório, no diff de
toda revisão e no bundle do aplicativo.

Remova antes de commitar:

```bash
dart run tool/limpar_svg.dart assets/icons/nome-do-icone.svg
```

Sem argumento, o comando varre todos os SVG da pasta:

```bash
dart run tool/limpar_svg.dart
```

Ele apaga apenas `<metadata>…</metadata>` e comentários XML — `path`, `viewBox`
e `currentColor` ficam intactos. Reescreve o arquivo só quando há algo a
remover, e imprime quantos bytes saíram.

Confira depois:

```bash
wc -c assets/icons/*.svg          # ícone limpo: algumas centenas de bytes
grep -i c2pa assets/icons/*.svg   # não deve retornar nada
```

Os 19 ícones atuais já estão limpos.

## Como esses arquivos chegam na tela

1. O SVG entra nesta pasta, em kebab-case.
2. O nome é registrado no enum `NomeIcone`, em
   `lib/design_system/widgets/app_icone.dart`. **Ícone que não está no enum
   nunca é desenhado** — não existe forma de carregar SVG por string no app.
3. `dart run tool/compilar_icones.dart` converte os SVG para o formato binário
   `.svg.vec` em `assets/icons_vec/`, que é o que o `pubspec.yaml` declara. O
   parse do XML acontece no build, não no primeiro frame de cada ícone.
4. Na tela, sempre `AppIcone(nome: NomeIcone.confirmacao)`. Cor e tamanho
   vêm do `IconTheme` em volta, ou por parâmetro.

`test/design_system/app_icone_test.dart` falha se qualquer passo faltar: ícone
do enum sem arquivo, arquivo sem entrada no enum (**arquivo órfão também é
erro**), ou `.vec` faltando/sobrando.

O que o teste **não** pega é `.vec` desatualizado: o arquivo existe, tem o nome
certo, e mesmo assim não corresponde mais ao desenho do SVG. O teste compara
nomes, não conteúdo. Quem pega isso é o CI
([`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)): ele roda o
compilador e falha se algum `.vec` mudar — recompilar arquivo já atualizado
reescreve bytes idênticos, então árvore suja significa ícone fora de sincronia.
Se o CI acusar, rode `dart run tool/compilar_icones.dart` e commite o
resultado.

Lembrete: **esta pasta é espelhada com a landing page.** Adicionar, remover ou
redesenhar ícone aqui exige a mesma alteração no outro repositório.

