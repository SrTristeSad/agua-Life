# Fase 33 — isolamento e seleção do peixe

## Diferença concreta da v32

O recipiente de isolamento possui 98×46 pixels no PNG original e é apresentado em x=70..168, y=274..320. A interface anterior posicionava peixes em x=83 e 147, com corpos adultos de largura 50px: o primeiro ficava 12px fora do recipiente e o segundo, 4px fora. Com caudas altas, partes também ficavam encobertas pelos comandos inferiores, que começam em y=299.

Agora a **apresentação** usa os centros x=96/144, y=286. Os sprites são redimensionados apenas na bandeja com escala `min(1,48/largura,24/altura)`; assim, toda combinação adulta cabe em x=70..168 e y=274..298. As dimensões nativas 21/35/50 pixels dos aquários não foram alteradas. Essa escala do isolador é uma adaptação de legibilidade e **não uma fórmula autenticada pelo JAR**.

Ao selecionar um peixe no isolamento, ele é exibido na moldura superior em (91,53), com sprite em escala original e comandos SELECT/BACK disponíveis. O segundo peixe permanece no compartimento. O desenho não consome RNG, não muda índices genéticos ou condição física e não altera o save.

## Validação

`tests/v33_isolation_layout.lua` percorre 441 combinações adulto-corpo/barbatana com posições e tamanhos do atlas, verifica as duas vagas, seleção, teclas e invariância do estado. `core/retro_smoke.lua` agrega as telas `21-isolamento-dois` e `22-isolamento-selecao` às capturas executadas no binário real LÖVE via GitHub Actions.

Permanecem pendentes a inspeção com emulador J2ME, a geometria exata de menus ainda sem capturas e a execução Android.
