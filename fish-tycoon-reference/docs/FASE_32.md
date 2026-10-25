# Fase 32 — tamanhos reais dos sprites conforme a idade

O JAR J2ME 1.0.1 contém, na classe `m`, os métodos `a()` (largura),
`b()`/`c()` (altura): idades 0–5 usam corpo 21×8; idades 6–19 usam corpo de
35 pixels com altura específica por variedade; adultos (20+) têm corpo de
50 pixels, com alturas vindas das tabelas em `j`.

A v31 ainda redimensionava quase todos os peixes para 85%, apesar de as artes
extraídas já estarem em suas dimensões originais. A v32 elimina esse fator
artificial na tela clássica. As 441 combinações de corpo e barbatana passam a
compartilhar uma única definição de geometria em `ui/fish_geometry.lua`.

Essa geometria alimenta limites de posição e áreas de toque. As barbatanas
podem ser mais altas que o corpo adulto e foram incluídas no cálculo do limite
vertical. A moldura amarela mantém a geometria e a âncora da imagem de
referência; a pequena diferença de altura do maior sprite em relação à moldura
continua exigindo conferência visual no MIDlet original.

A alteração é puramente visual. Não modifica `core/game.lua`, arquivos PNG,
músicas nem o formato dos salvamentos. O novo teste `tests/v32_fish_sizes.lua`
valida três idades, 21 formas juvenis, 441 combinações adultas, áreas de toque,
limites e seleção. A execução nativa usa o fluxo existente de capturas no
GitHub Actions.
