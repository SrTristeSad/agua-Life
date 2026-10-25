# Fase 4 — simulação, genealogia e capacidade

## Mudanças confirmadas pelo JAR

- `m.a(int,int,int,int,int)` calcula o corpo e a barbatana a partir da média inteira dos pares de valores de entrada (a classe `m` não expõe sexo como campo independente).
- `o.a(m,int,int)` armazena os índices do parceiro de acasalamento em `g[5]` e define `g[3] = idade + 3`. O metodo `m.h()` testa `g[3] < idade`, portanto o hatch novo ocorre depois do quarto incremento de idade. Incubacoes legadas usam o prazo anterior para preservar saves.
- `n.b(m,boolean)` divide o tempo acumulado por `60 * {5,10,15}`, conforme configuração 19/20/21. A Lua usa 10 minutos como padrão e botão para alterar.
- `o.b(m,int)` e `o.a(int,int,int,int,int,int)` verificam um limite de 18 peixes nos compartimentos J2ME; o Lua adota 18 no principal, secundário e vendas. Isolamento continua em 2 por decisão de UX.
- Para idade abaixo de 6, `m.m()` retorna origem X=100 e `m.l()` retorna origem Y=296; recorte de 21×8 no atlas.

## Ainda experimentais

- Número de filhotes por gestação, detalhes do nascimento, mutações, preços de negociação, doença e buffs mágicos.
- Nenhum efeito dos sete peixes especiais foi confirmado no JAR.
- Os jovens (6..19) usam os 21 recortes de `j.K`, `j.S[1]` e `j.R[1]` recuperados do JAR.

## Persistência

`version=4` migra automaticamente versões 2 e 3; não substitui variedades atuais; converte gestação em curso e preserva fração do ciclo. O save continua separado no diretório próprio do LÖVE.
