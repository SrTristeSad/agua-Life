# Fase 21 — compras e pesquisas em 240×320

O foco é a apresentação do Fish Tycoon Java. As referências fornecidas mostram o aquário e a seleção, mas não a loja ou todas as pesquisas; por isso não atribuímos equivalência pixel a pixel a estes menus.

A loja usa miniaturas de `assets/original/store.png` já presente no projeto, até 4 itens por página, destaque de seleção, preço, descrição e botão BUY distinto da seleção. `ui/retro.lua` preserva proporções dos sprites e funciona sem o atlas (reserva). O motor de compra e os preços de `core/catalog.lua` não mudaram.

Pesquisas exibem os três campos existentes com níveis, indicador de progresso, descrição, START/MAX e o trabalho ativo. Custos, tempos e publicidade continuam sendo aproximações do port Lua.

A suíte `tests/v21_shop_research.lua` cobre visualização dos sprites, seleção sem comprar, compra efetiva, paginação, limite de pesquisa, BACK e ausência do atlas. As 34 suítes Lua locais passaram. O workflow nativo LÖVE foi ampliado para capturar 9 telas em resolução escalada de 480×640, incluindo duas páginas de suprimentos e pesquisas. Capturas são verificação de renderização, **não** prova de fidelidade 1:1.

Não alterar genética e pesquisa somente para simular aparência de menus; preservar salvamentos v9. Próximas prioridades: fonte bitmap do JAR, layouts dos menus ainda sem referência e inspeção das capturas reais.
