# Fase 15 — conferência de genética e pesquisas pelo bytecode

## Mutação por gestação

Em `n.a(m,o,int)` no JAR 1.0.1, a chance de alteração é avaliada antes de todas as chamadas de `o.a(IIIIII)V` responsáveis pelos nascimentos base e extras. O método atualiza uma única vez o parceiro armazenado em `m.g[5]` via `m.b(II)V`. Portanto, filhotes da **mesma gestação** devem herdar a mesma combinação de corpo/barbatana, mesmo quando uma planta de fertilidade aumenta a quantidade.

`core/game.lua` passou a chamar `combineParents` uma vez antes do laço de eclosão. Os filhotes compartilham os valores herdados, mas recebem cópias independentes da tabela Lua de genes. O salvamento continua no formato 9.

A operação confirmada em `m.a(IIIII)V` é a média inteira dos dois índices recebidos para cada componente. Mutação exige peixe especial ativo e tem chance Java `rand(100) <= 15`; a seleção da parte usa `rand(100) <= 49`.

## Pesquisas

O teste `tests/v15_jar_genetics.lua` também cobre níveis biológicos de `n.c(m)` e reserva alimentar em `n.a(m,boolean)`. Os resultados confirmados são: níveis de nutrição 1/2/3 consomem reserva em 100%, 61% e 31% dos ciclos, respectivamente. O quarto nível, de 20%, é extra do port Lua; custos, duração e publicidade continuam aproximados.

## Validação

Os testes da fase usam o interpretador Lua e fixtures determinísticas. Não equivalem a executar o MIDlet em emulador J2ME e não substituem teste visual no LÖVE. Foram mantidas todas as artes e músicas anteriores, sem alterações.
