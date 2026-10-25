# Fase 20 — barra J2ME, espécies e controles

## Referências fornecidas

Nas capturas originais de 240×320, o aquário ocupa a maior parte da tela. Na barra superior aparecem miniaturas dos tanques e ferramentas ilustradas. Ao selecionar um peixe, a barra superior passa a mostrar **FED**, **HEALTH**, nome da espécie composto por barbatana + corpo e **AGE**; os softkeys na parte inferior exibem **SELECT** e **BACK**.

## Implementação verificável

- `ui/retro.lua`: barra de 11 botões com ícones raster do `assets.png`, recortados com `newQuad`; três miniaturas usam `tank1.png`, `tank2.png` e `tank3.png`. Quando `assets.png` não está instalado, permanecem botões funcionais com letras de reserva. Os sprites comerciais adicionais não foram incluídos no repositório público.
- `core/catalog.lua`: nomes de corpo das entradas 51–71 e de barbatana das entradas 72–92 da tabela `E_Ingles.tsv` extraída do JAR. Nenhum ID ou fórmula genética alterado.
- `Retro:statsBar`: passa a mostrar os dois nomes autênticos, separados em linhas.
- `Retro:drawTank`: a arte do recipiente do isolamento é desenhada **antes** dos peixes. Corrige um defeito em que o recipiente ocultava o peixe isolado.
- Tanque de vendas: etiqueta simples **For Sale!**, ainda não o recurso visual definitivo do JAR.
- Navegação de teclado tradicional (2/4/6/8, 5), com suporte adicional de mouse/touch; atalhos da barra abrem loja, pesquisa, espécie, tratamento, reprodução ou alimentam.
- `tests/v20_visual_controls.lua`: oito verificações novas, incluindo 441 combinações de nomes, cortes válidos do atlas, funcionamento dos botões, teclado e ordem de desenho.

## Limitações e próximos passos

O atlas comercial ainda depende do importador local `scripts/import_j2me_assets.py`, portanto os screenshots automáticos do **repositório público** utilizam os símbolos de reserva. O `.love` criado para teste local, a partir do JAR fornecido, inclui o atlas e os ícones. Capturas de menus e loja que não foram fornecidas não podem ser afirmadas como reconstrução 1:1. Faltam os glifos bitmap exatos, a navegação das telas de preço e compra equivalentes ao JAR e inspeção visual comparativa em emulador J2ME.

Não foi apagada ou reescrita nenhuma arte existente. Salvamentos v9 continuam compatíveis. A interface da v19 permanece o ponto de partida.