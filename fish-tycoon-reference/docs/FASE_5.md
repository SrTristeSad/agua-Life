# Fase 5 — Regras adicionais do JAR e mercado

## Evidências do bytecode

- `n.a()` inicializa `b[21][21]` com a soma de `g[] + h[]` e 13 exceções, e `a[21][21]` com `-1`.
- `n.a(int,int)` inicializa a cotação na primeira ocorrência: `desvio = j.c(b/5)`; com `j.c(100) <= 49`, sinal negativo, caso contrário positivo. Esta parte foi implementada em `core/market.lua`.
- `n.d(m)` chama a inicialização da cotação da variedade quando o peixe passa a adulto, e registra descobertas especiais. A v5 adia as descobertas até a maturidade.
- `n.a(int,o,int)` compara valores de `a[][]` e `b[][]` para vender e usa limiares de sorteio `30`, `10`, `4` e `1` contra uma janela de `900`. A v5 aproveita esta hierarquia, mas o número de visitas (6 por ciclo) é escolha do protótipo.
- `n.a(m,o,int)` cria um filhote por padrão, mais um se o índice 0 está presente no tanque. Uma terceira condição depende de `b.d(16)`, ainda não mapeada.
- `n.c(o,int)` calcula `j[0..6]` por consulta do peixe mágico presente no tanque, não apenas descoberto no catálogo.
- `n.a(m,o,int)` oferece mutação de 1 passo em um índice parental com `j[5]` e teste `j.c(100)<=15`. Isso foi aplicado ao cruzamento Lua quando a variedade mágica correspondente está no isolamento.

## Ainda adaptado

- Trânsito de compradores, intervalo de tentativas, bônus de publicidade, regras exatas de pesquisa, saúde, equipamentos e contagem extra via `b.d(16)`.
- Nascimentos do isolamento chegam ao tanque principal na interface Lua.
- `core/catalog.lua` ainda atribui nomes e benefícios provisórios a cinco efeitos mágicos.

## Preservação

A v5 atualiza `version=5` e mantém `fromTable()` compatível com v2–v4. Os preços pedidos por cada peixe, a gestação em andamento e os peixes nos tanques não são reescritos; as novas cotações de mercado são criadas sob demanda.
