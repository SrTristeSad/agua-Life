# Fase 26 — tanque de vendas original

A imagem `tank3.png` do JAR mede 240x156 e ja contem duas placas `For Sale!` fixas nos extremos do solo. Posicionadas na composicao em y=122, as placas ficam no cascalho como na imagem de referencia enviada pelo usuario.

A v25 desenhava uma segunda etiqueta por peixe adulto no tanque de vendas. Como essa etiqueta seguia o peixe, gerava placas duplicadas flutuando no aquario. A v26 remove esses overlays: apenas a imagem original traz os sinais.

Quando o arquivo `splash.png` comercial nao foi importado, o titulo reserva usa `FISH TYCOON / MOBILE`, sem adicionar marca do port.

Os testes v25 foram atualizados, e a nova suite `v26_sale_art` confirma o fundo `tank3.png`, a selecao de peixe e a ausencia de sobreposicao. O driver nativo e o validador Python agora testam 11 telas, incluindo vendas e selecao no tanque de vendas.

Nao foram alterados imagens PNG, mercado, genetica, pesquisas ou formato de saves. A equivalencia completa 1:1 ainda requer as capturas das demais telas J2ME.
