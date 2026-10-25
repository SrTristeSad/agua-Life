# Fase 17 — saúde, alimentação e pesquisas do bytecode Java

Referência: JAR `Fish_Tycoon_240x320-111845-mobiles24.jar`, classe `n`, método privado `c(m)` (desassemblagem com `javap -c -p`).

## Regra recuperada

O método `n.c(m)` calcula a alteração biológica por corpo, barbatana e nível da pesquisa de ambiente, adiciona o bônus probabilístico (+1 cada) de dois equipamentos e, depois, executa:

1. Se `m.g()` (peixe doente) **ou** `m.a(7) < 5` (alimento insuficiente), um **delta positivo vira zero**.
2. Se `m.g()` (doença), o resultado recebe **-1**.
3. Atualiza a saúde do peixe com o delta resultante.

A função `Care.originalConditionDelta(body,tail,level,fed,diseased,bonuses)` representa essa etapa, testada com combinações positivas/negativas, níveis 1–3, doença e fome. Os bônus de pesquisa nível 4, peixe mágico e fome extrema do port Lua foram mantidos explicitamente como adaptações. O dano antigo de -4 por doença foi substituído pela penalidade Java de -1; a variação da saúde durante a partida pode mudar.

## Risco de doença e pesquisa

O método público `n.a(m,int)` calcula `base + 6 * argumento + 15 se idade > 600`. A assinatura `Care.originalDiseaseThreshold(body,foodLevel,exposure,age)` permite verificar essa expressão isoladamente. A versão anterior de dois argumentos continua válida. A regra aproximada de densidade e as proteções extras Lua permanecem separadas na função `Care.step`.

Pesquisas possuem três níveis confirmados no bytecode (1–3); o quarto nível de nutrição, custos, prazos e marketing são adaptações. O campo `source` do painel agora reflete essa distinção.

## Testes e integridade

Executar `texlua tests/v17_biology.lua`, `texlua tests/run.lua` e o conjunto `tests/*.lua`; GitHub Actions testa também a interface no LÖVE real (Xvfb). Preservar os arquivos originais de sprites e músicas, o formato v9 de salvamento e o projeto preexistente.
