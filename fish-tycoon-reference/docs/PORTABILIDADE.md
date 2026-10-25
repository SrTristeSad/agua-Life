# Rastreabilidade: Kotlin -> Lua

| Referencia fornecida | Lua | Estado |
|---|---|---|
| `Fish.kt`: estagios 0-5, 6-19, >=20 | `core/game.lua`: `fishStage` | Portado |
| `Catalog.kt`: 6 especies, precos e nomes | `core/catalog.lua` | Portado, nomes originais da *implementacao Kotlin* |
| `Config.kt`: ano e incubacao de 1800000ms | `core/config.lua`: 1800s | Portado |
| `Config.kt`: fome, regeneracao, doenca | `core/game.lua`: `_tick` | Portado e expandido |
| `Aquarium.kt`: tanque principal, isolamento, vendas | `core/game.lua`: `tanks` | Portado |
| `Aquarium.kt`: eclosao no tanque principal | `core/game.lua`: `_hatch` | Portado e corrigido |
| `Aquarium.kt`: cruzamento permitia um unico adulto e bloqueava tanque cheio | `core/game.lua`: `breed` | Corrigido: 2 adultos, sexos diferentes, saudaveis |
| `Aquarium.kt`: mutacao troca arbitrariamente a especie | `core/game.lua`: `inherit` | Substituido por alelos herdados, regra propria |
| `Aquarium.kt`: chance de vender adulto | `core/game.lua`: `_tick`, `sell` | Expandido: preco e publicidade influenciam |
| `GameView.kt`: peixes em formas basicas | `ui/view.lua` | Redesenhado (peixe vetorial, UI propria) |
| `MainActivity.kt`: sempre recomecava | `core/storage.lua`, `core/json.lua` | Corrigido, save persistente |
| Notas J2ME: segundo tanque, pesquisa, suprimentos | `core/game.lua`, `core/catalog.lua` | Regras aproximadas, funcionais |
| Notas J2ME: 7 peixes magicos | `core/catalog.lua`, `core/game.lua` | 7 descobertas proprias via genotipos |
| Notas J2ME: venda com clientes, precos | `core/game.lua` | Modelo probabilistico proprio |

## Regras confirmadas apenas por texto do J2ME

- Objetivo de descobrir 7 peixes magicos.
- Eclosao em aproximadamente 30 minutos, adultos com idade 20.
- Fome, doenca, remedios, aquario principal, isolamento, venda, pesquisa e equipamentos.
- Tempo offline.

## Parametros ainda hipoteticos

- 30 min para cada ano de peixe, probabilidades de doenca/compra/mutacao e custos dos itens (balanceamento obtido do prototipo Kotlin ou criado aqui, **nao do bytecode J2ME**).
- O esquema de dois pares de alelos, especies hibridas e sequencias que liberam os 7 efeitos.
- Frequencia de clientes e reacao ao preco (modelo simplificado).
- Quantidade de filhotes, custos e duracao das pesquisas e efeitos de equipamentos.

## Funcionalidades ainda nao reconstruidas de maneira fiel

- Recursos originais PNG/MIDI, sprites/animacoes de especies e comportamento original dos peixes.
- Encontros com clientes e falas especificas da loja J2ME.
- Todos os ornamentos/planta especies, ovo incomum/raro e inventario do J2ME.
- Tabelas binaras `1.dat` e formulas reais das classes `m`, `n`, `l` do jogo J2ME.
- Exportacao como APK Android personalizado e testes com runtime grafico no aparelho.

O objetivo desta entrega e um **jogo independente jogavel em Lua**, nao a alegacao de equivalencia binaria com o Fish Tycoon original.
