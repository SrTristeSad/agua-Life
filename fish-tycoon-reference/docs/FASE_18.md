# Fase 18 — risco coletivo de doença recuperado do JAR

## Evidência: `n.a(o)` e `n.a(m,int)`

O método público `n.a(o)` da classe `n` percorre os três vetores `o.i[0..2]` e incrementa `i4` quando `m.g()` indica doença. Só depois de terminar essa contagem o método percorre os peixes, chamando `n.a(m, int)` (via `n.a(m, int, boolean, boolean, boolean, boolean, int)`) com o valor fixo de `i4`. Assim, novas doenças no ciclo não alteram o risco dos peixes subsequentes até a próxima atualização.

O método `n.a(m,int)` começa retornando imediatamente se o peixe já estiver doente. A chamada é condicionada por `m.d()`, que identifica adultos a partir da idade 20. Seu cálculo de risco é `base + 6 * i4 + (idade > 600 ? 15 : 0)`, comparado com `j.c(10000)`. A planta de cura e o caracol de limpeza reduzem o limiar pela metade, como já implementado.

## Implementação

- `core/care.lua` expõe `diseaseExposure(game)` e mantém `originalDiseaseThreshold(body,foodLevel,exposure,age)`.
- `core/game.lua` calcula a contagem uma vez, no começo de `_tick()`, e a transmite a `Care.step`.
- Foram removidas as multiplicações por lotação e fome crítica que não estão presentes nessa fórmula Java. O sistema de fome e os bônus experimentais de outros módulos permanecem como adaptações do port Lua.
- `tests/v18_contagion.lua` testa adultos, filhotes, contagem dos três tanques, efeito por geração dentro do mesmo ciclo, e integridade dos salvamentos.

**Ressalva:** o JAR usa três tanques indexados por `o.i` e uma referência separada de isolamento em `l.b`. O mapeamento para `main/second/sale` reflete a organização do projeto Lua; deve ser verificado em emulador J2ME antes de declarar equivalência total de distribuição. Os custos e durações das pesquisas e a genética não alterada nesta fase continuam parcialmente aproximados.
