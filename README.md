# agua-Life — peixes procedurais em Lua

Jogo original em Lua/LÖVE 11.4+, com **21 corpos, 21 caudas, 12 paletas e 6 padrões**, compondo 441 espécies anatômicas. A arte e os cenários são desenhados por código.

## Novidades: genética e saúde
- DNA próprio por peixe, com dois alelos de corpo, cauda, cor e estampa.
- **N** cruza o peixe selecionado com o seguinte, criando um filhote que herda alelos dos dois pais (limite de 30 exemplares).
- **F8** ou botão **DNA** mostra genes, resistência, predisposição, doenças e saúde.
- **F9** ou **Mortes** exibe o relatório da última morte, com causa provável, doença encontrada, alimentação e grau de confiança.
- **F** alimenta o peixe selecionado; **H** aplica tratamento à doença ativa.
- A cada 5 segundos de jogo ocorre uma atualização biológica. Fome e infecções prejudicam a saúde; peixes podem morrer. Até 30 relatórios permanecem durante a sessão.
- A predisposição genética **não** é diagnóstico. O relatório de morte é uma estimativa, não uma prova.

## Executar
Instale LÖVE 11.x e abra a pasta com `love .`. Para testar a lógica sem GPU, execute `texlua tests/genetics.lua` na raiz.

## Situação da reconstrução 1:1
A vitrine atual de `agua-Life` é um projeto próprio, **não é uma cópia integral do Fish Tycoon Lua**. A migração fiel do motor original e do salvamento, assim como as novas artes definitivas, são trabalhos separados; não foram concluídos nesta atualização. O repositório `Fish-Tycoon-Lua` não foi alterado.
