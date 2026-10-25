# Fase 36 — recorte da selecao de peixes

Na referencia J2ME 240×320, a moldura amarela ocupa x63..119 e y34..71 (56×37), com interior de 54×35 pixels. O atlas inclui barbatanas adultas de ate 39 pixels de altura; sem um recorte, os sprites sobrepunham a moldura e o HUD.

O renderizador passou a limitar exclusivamente o **peixe selecionado** ao interior da moldura. O fundo e restaurado com a mesma geometria usando `tanktop.png`. A rotina compartilhada converte coordenadas logicas para pixels da janela LÖVE, funciona em escala nao inteira e preserva os scissor anteriores.

A suite `tests/v36_selection_scissor.lua` verifica os limites, a restauração, escalas 2× e 1,95× e o peixe de barbatana alta. O smoke test nativo inclui a 24ª tela. Genetica, dinheiro, crescimento, recursos comerciais e saves permanecem inalterados. A comparacao completa com o MIDlet continua pendente.
