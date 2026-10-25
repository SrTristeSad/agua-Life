# Fase 8 — compradores, incubação e progresso de pesquisa

## Continuidade

Projeto derivado da **v7**, sem reinicialização. Mantém identidade LÖVE `mar_de_isola_lua`, nome do arquivo de salvamento e recursos JAR (imagens e música) do pacote anterior. O esquema do jogo foi atualizado de 7 para 8. Os estados v2–v7 são migrados na abertura, sem reescrever valores de dinheiro, peixes, genes, cotações ou itens.

## Mercado — novas evidências do JAR

Fontes técnicas locais: `fish_jar_analysis/disassembly/n.txt` (método `n.a(int,o,int)` perto do offset 1868), `fish_jar_analysis/disassembly/l.txt` (lógica do modo de loja perto da linha 5840) e `fish_jar_analysis/disassembly/m.txt` (estado de venda de cada peixe). O material de desassemblagem está no ZIP de engenharia anterior, não embutido no executável.

- O método `n.a(int,o,int)` percorre o tanque de vendas e **retorna imediatamente** ao vender um peixe. Portanto, no máximo uma compra por chamada.
- Os patamares da procura são `30`, `10`, `4` e `1`, multiplicados por `floor((publico+2)/2)`. Cada patamar é comparado com `j.c(900)` (inteiro em `0..899`). Se o preço pedido for pelo menos o dobro do preço-base, não há venda nessa rotina.
- Os valores são comparados com a cotação gerada para a variedade, já implementada na v5. Peixes em certos estados de venda (`m.g()` no Java) podem exigir um sorteio extra. Essa distinção de estado **ainda não foi reconstituída** no esquema Lua.
- A rotina principal `l` tenta processar compradores na tela da loja, com animações e intervalos variados (há valores de 350 ms e 5000 ms, este último após uma compra). **Não** há confirmação de um intervalo universal de 5 s para todo comprador.

## O que a versão 8 implementa

1. `core/market.lua`: `Market.advance` passa a acumular tempo simulado e processa visitas de clientes sem depender de o peixe envelhecer. `Market.step` representa um comprador, avalia os adultos na ordem e encerra na primeira venda. A interface exibe contagem de clientes, desistências e contagem regressiva da visita seguinte.
2. `Market.chancePerVisit`: aplica os patamares recuperados e o ajuste `(limiar+1)/900` pela comparação `<=` do JAR. As equivalências de publicidade, decoração e público continuam **aproximações locais**. O intervalo fixo **5 s simulados** é escolha de jogabilidade, não uma regra confirmada do JAR.
3. `Game:incubationInfo`: usa a gestação por idade previamente reconstruída, mostrando os ciclos que faltam para a eclosão sem alterar sua duração.
4. `Game:researchInfo`: expõe o progresso percentual e tempo restante das pesquisas, com barra visível na interface. Custos, níveis extras e prazos ainda são adaptações do port, não tabelas verificadas do original.
5. Quando ovos **comprados** estão prontos e o tanque principal está cheio, eles aguardam uma vaga. Não se perde a compra nem se duplica o nascimento no salvamento.
6. Migração para o esquema v8 inclui `market.elapsed=0` em salvamentos anteriores; em salvamentos v8 o contador fracionário é preservado.

## Casos de teste

A partir da raiz:

```sh
texlua tests/run.lua
texlua tests/v4_regression.lua
texlua tests/v5_regression.lua
texlua tests/v6_regression.lua
texlua tests/v7_regression.lua
texlua tests/v8_regression.lua
texlua tests/view_smoke.lua
texlua tests/v5_ui_smoke.lua
texlua tests/v6_ui_smoke.lua
texlua tests/v7_ui_smoke.lua
texlua tests/v8_ui_smoke.lua
texlua tests/lifecycle_smoke.lua
texlua tests/jar_resources_smoke.lua
texlua tests/v8_performance.lua
```

O teste de performance simula 24 h com loja aberta e 18 peixes com preço inviável e verifica as 17.280 visitas sem venda. A execução foi feita no ambiente Lua do `texlua` (não é um benchmark em dispositivo).

**Limites conhecidos:** falta teste de janela real do LÖVE, a distribuição de clientes ainda é adaptada, não existem animações individuais de compradores nem mapeamento integral da pesquisa original. Este arquivo documenta a diferença entre reconstituição comprovada e escolhas do port.
