# Fase 7 — Medicamentos, mutações e equipamentos

## Continuidade

Derivada diretamente da v6: permanecem a genética 21×21, sete peixes mágicos, aquários, cotações, música, sprites por idade, sistema offline e controles. O schema de salvamento passou de 6 para 7, com migração dos estados v2–v6 e identidade LÖVE inalterada (`mar_de_isola_lua`).

## Descobertas diretamente verificadas no bytecode J2ME 1.0.1

Referência: `/mnt/data/fish_jar_analysis/disassembly/n.txt` no material de análise (não distribuído neste pacote). `j.c(100)` retorna um inteiro de 0 a 99.

| Rotina original | Ponto de referência | Regra recuperada | Lua |
| --- | --- | --- | --- |
| `n.a(o,int)` | ramo `m.a(7)` | comida soma +50; se exceder 100, reduz 2 de saúde | `Treatments.feed` |
| `n.a(o,int,int)` | `j.c(100) < 40`, `m.a(4,3)` | dose de Ick/fungo tem 40% de chance de tratar a doença correspondente (exceto condição especial do tutorial) | `Treatments.cure` |
| `n.b(o,int,int)` tipo 2 | `m.a(6) + j.c(10) + 6` | vitaminas +6 a +15 de saúde | `Treatments.vitamin` |
| `n.b(o,int,int)` tipo 3 | teste idade <=40, `j.c(5)+2` | hormônio +2 a +6 de idade em peixes de idade até 40 | `Treatments.hormone` |
| `n.b(o,int,int)` tipo 4 | `j.c(100) <=25` | químico desconhecido possui 26% de chance de mudar um índice de corpo/barbatana em ±1 | `Treatments.mutagen` |
| `n.c(m)` | `b.d(9)` e `b.d(10)` | até +1 saúde cada com sorteio `j.c(100)<=40` (41%) | `Care.step` |
| `n.a(m,boolean)` | `b.d(13)`, `j.c(100)<=20` | planta nutritiva pode devolver +5 de reserva se o peixe está quase sem alimento | `Care.step` |
| `n.a(m,int)` | `b.d(15)` e `b.d(11)` | prevenção de doença: planta de cura divide o limiar por 2; caracol pode dividi-lo por 2 em 50% dos sorteios | `Care.step` |
| `n.a(m,int)` | idade `>600` | aumento de 15 no limiar de risco para peixes muito velhos | `Care.step` |
| `n.a(m,o,int)` | `n.j[0]`, `b.d(16)` | um filhote base, mais um com peixe mágico de fertilidade e mais um com planta de fertilidade | `Game:_hatch` |

**Nota de correspondência dos itens:** identificações de equipamentos 9/10/11/13/15/16 foram associadas aos nomes de seus itens usando o conjunto de textos recuperados e a ordenação funcional dos flags. As fórmulas numéricas podem ser observadas no bytecode, mas a correspondência exata de cada flag com os recursos de menu ainda requer ensaio dinâmico no emulador J2ME.

## Adaptações documentadas (não originais comprovadas)

- O Java aplica esses consumíveis ao conjunto de peixes do tanque. A interface Lua permite selecionar e tratar um peixe por vez para manter o fluxo já implementado.
- Os valores de venda de medicamentos e das novas plantas no catálogo Lua ainda são preços próprios e **não** preços confirmados da versão Java.
- A nova planta de cura e fertilidade utiliza a mesma interface de equipamentos globais do projeto, em vez de individualizar instalação por tanque.
- Os multiplicadores experimentais de lotação, fome e efeitos mágicos mantidos das versões anteriores continuam sinalizados como adaptações.
- A representação de doenças em Lua distingue `ick`/`fungus`, sem reproduzir integralmente os estados internos 1/2/3/0 do JAR; logo, não é uma reconstrução total.
- O teste de chance da mutação reconstitui seus limiares e limites, mas a sequência exata de todos os sorteios e animações do Java não está validada.

## Integridade dos salvamentos

`Game.fromTable` aceita arquivos v2–v7. As chaves adicionais `supplies.mutagen`, `stats.treatments`, `stats.failed_treatments`, `stats.mutations` passam a existir com 0, sem substituir o dinheiro, idade, genótipos, preços, peixes e instalações anteriormente salvos. O arquivo salvo mantém o mesmo nome `fish_tank_save.json`, dentro do diretório de dados do LÖVE.

## Execução dos testes

A partir da raiz do projeto:

```bash
texlua tests/run.lua
texlua tests/v4_regression.lua
texlua tests/v5_regression.lua
texlua tests/v6_regression.lua
texlua tests/v7_regression.lua
texlua tests/view_smoke.lua
texlua tests/v5_ui_smoke.lua
texlua tests/v6_ui_smoke.lua
texlua tests/v7_ui_smoke.lua
texlua tests/lifecycle_smoke.lua
texlua tests/jar_resources_smoke.lua
```

Os testes de interface são simulações das chamadas gráficas, não capturas do jogo em execução. Ainda falta validar com LÖVE 11.4 em uma janela física e realizar uma build Android.
