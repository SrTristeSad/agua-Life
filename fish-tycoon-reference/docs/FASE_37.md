# Fase 37 — trofeus com a arte original do JAR

A versao anterior mostrava sete nomes em texto, sem utilizar o arquivo
`trhopy_ball.png` existente no JAR J2ME 1.0.1 (grafia original, 88x88 px).
A nova tela TROPHY apresenta sete esferas: especies descobertas mostram sua
combinacao de corpo/barbatana, enquanto outras permanecem ocultas.
A selecao visual de uma esfera exibe o nome exato da variedade do catalogo.

O posicionamento 4+3, as areas de toque e os textos complementares sao
**adaptacoes do port**, pois ainda nao existe captura de tela autentica do
menu de trofeus para afirmar equivalencia pixel a pixel. A esfera e o
asset original; as formulas biologicas nao sao afetadas.

`scripts/import_j2me_assets.py` extrai esse arquivo do JAR possuido pelo
usuario junto aos demais recursos opcionais. `assets/original/trhopy_ball.png`
e ignorado pelo Git e nao e publicado no repositorio aberto. Sem a arte,
a tela ainda permite consultar todos os trofeus com simbolos de reserva.

A suite `tests/v37_trophy.lua` verifica renderizacao com e sem recurso,
sete slots selecionaveis, exibicao de variedades e invariancia de cash/RNG/save.
O CI captura tambem a tela 25 no LÖVE real. Nenhum dado persistido foi alterado.

O teclado 4/6 desloca a selecao amarela junto ao foco, eliminando
os dois destaques simultaneos que apareceram no primeiro teste nativo.
