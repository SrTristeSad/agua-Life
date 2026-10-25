# Fase 38 — disponibilidade real na loja e nas pesquisas

Nas versoes anteriores, o botao `BUY` aparecia ativo para equipamento ja instalado, tanque 2 desbloqueado, ovos sem capacidade ou saldo insuficiente. `START` nas pesquisas nao mostrava o preco e a duracao da proxima fase, e podia ser apertado com saldo insuficiente. O motor rejeitava essas acoes depois do toque. Isso escondia o motivo da rejeicao e atrapalhava a jogabilidade.

Esta fase conecta os estados de interface diretamente as precondicoes que ja existem em `core/game.lua`. O botao de compra mostra `OWN`, `FULL` ou `NO $` conforme o caso, e a linha de preco exibe a quantidade de suprimentos existente. A interface de pesquisa usa `Config.RESEARCH_COSTS` e `Config.RESEARCH_SECONDS` para apresentar preco e duracao do proximo nivel, além de indicar quando `START` nao pode ser acionado. Nao existem custos inventados ou cobrancas automaticas nesta fase.

**Importante:** custos e duracoes do motor sao configuracoes experimentais do port Lua, **nao** formulas autenticadas do JAR. Tambem nao ha evidencias suficientes para declarar esta composicao visual exatamente igual a do MIDlet. Nenhum arquivo PNG, audio, regra de simulacao ou save foi modificado.

`tests/v38_shop_research_states.lua` cobre falta de dinheiro, equipamentos ja instalados, falta de espaco para ovos, itens consumiveis, pesquisas concorrentes, custos e duracoes. O LÖVE nativo acrescenta duas capturas para inspecao visual.
