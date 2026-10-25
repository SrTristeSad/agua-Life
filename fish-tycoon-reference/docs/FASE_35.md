# Fase 35 — moldura de seleção e fixture visual equivalente

A captura de referência do usuário apresenta o Greenfin Fruitfish, idade 21,
**no tanque de vendas**: `tank3.png` com as placas `For Sale!` pintadas no solo.
As capturas de comparação anteriores usavam `tank1.png` e, por isso, davam a
impressão de divergência do cenário mesmo quando os assets eram corretos.

O smoke nativo passou a produzir `23-referencia-vendas.png` com o mesmo peixe
na sala `sale`; os demais indivíduos compõem uma fixture descartável do teste.
Nenhuma alteração é feita no save do usuário. As posições dos outros peixes
não são forçadas para coincidir com uma imagem estática.

O painel superior agora tem contorno roxo 216×33 com origem (12,0), brilho
inferior e preenchimento escuro semelhante à captura de 240×320. Isso elimina
a invasão da borda anterior na moldura amarela de seleção, cuja âncora continua
(91,53) com retângulo x=63..119, y=34..71.

`tests/v35_selection_panel.lua` valida a geometria do painel, os indicadores
de alimentação e saúde, a fixação do espécime selecionado, a arte do tanque de
vendas e a preservação da simulação. O GitHub Actions deve validar 23 capturas
reais do LÖVE.

**Limite:** o painel foi refinado com base em uma captura JPEG; não equivale a
reconstrução pixel a pixel do desenho vetorial/bitmap do Midlet em execução.
