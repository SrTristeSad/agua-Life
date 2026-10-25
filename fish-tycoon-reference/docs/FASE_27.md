# Fase 27 — menu e navegação com nomes do MIDlet

## Fonte de referência

A tabela inglesa decodificada do arquivo `1.dat` do JAR Fish Tycoon 1.0.1 registra os comandos de menu **RESUME** (índice 1), **START NEW GAME** (2), **OPTIONS** (3), **TROPHY** (4), **STATS** (5), **HELP** (6), **ABOUT** (7), **MORE GAMES** (8) e **EXIT** (9). A versão Lua v26 mostrava opções provisórias como `RETURN TO TANK`, `FISH SUPPLIES`, `DISCOVERIES` e `SAVE AND MAIN MENU`. Estas palavras não correspondiam à nomenclatura desse menu Java.

A v27 passa a apresentar `RESUME`, `START NEW GAME`, `OPTIONS`, `TROPHY`, `STATS`, `HELP`, `ABOUT` e `SAVE & EXIT` em um painel compacto de oito linhas. **O desenho, número de entradas visíveis e disposição das opções ainda são adaptações**, pois faltam capturas do menu Java completo. O comando `MORE GAMES` não é mostrado porque o port não tem integração equivalente e não deve simular um link funcional; `SAVE & EXIT` significa salvar e retornar ao título, não encerrar o processo no desktop. Os nomes confirmados pelo JAR não provam que a ordem e a geometria estão corretas.

## Fluxos implementados

- **RESUME**: volta ao aquário sem recriar a partida.
- **START NEW GAME**: abre confirmação se há save. Ao cancelar, volta ao menu de origem (`pause` ou `title`); a gravação e a cópia de segurança continuam sob `core/storage.lua`.
- **OPTIONS**: retorna ao menu de origem.
- **TROPHY**: abre a coleção de sete peixes mágicos já existente.
- **STATS**: mostra contagens e valores presentes no motor, sem alterar o estado.
- **HELP**: documenta os comandos Lua atualmente funcionais; ainda não é uma cópia do tutorial Java.
- **ABOUT**: mantém o retorno contextual, sem apresentar o port como oficial.
- **SAVE & EXIT**: retorna ao título somente após a callback de salvamento indicar sucesso. O controle de suprimentos e pesquisa permanece acessível na barra de 11 ícones dos aquários.

## Testes e limites

- `tests/v27_menu.lua`: rótulos, dimensões, troca de telas, confirmação, cancelamento, callback de salvamento e retorno contextual.
- `tests/v19_retro.lua` e `tests/v22_keypad.lua`: caminhos preexistentes adaptados às posições e aos comandos do novo menu.
- `core/retro_smoke.lua`: 15 capturas nativas em vez de 11, acrescentando menu atualizado, estatísticas, ajuda e troféu. `scripts/validate_retro_screenshots.py` verifica integridade dos PNGs.

Motor, recursos gráficos, músicas, genética e formato de save v9 não foram modificados. A interface ainda **não é comprovadamente 1:1** sem todas as capturas originais e testes Android.
