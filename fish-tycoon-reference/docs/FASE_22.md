# Fase 22 — controles e menus do celular Java

A v21 dependia do mouse nas telas iniciais e internas. A v22 adiciona foco direcional amarelo, teclas 2/4/6/8 e selecao por 5/Enter/Espaço. As teclas de navegacao por peixes continuam ativas no painel individual.

O atlas `assets.png` foi inspecionado para corrigir recortes equivocados de alimentacao e remedio. A barra superior agora cobre os 240 px sem dinheiro escrito fora das casas. As telas de menus usam `menutank.png` (240x256), ja incluido. Nenhum PNG novo foi adicionado ao GitHub.

A v22 preserva o motor Lua, a genetica e os salvamentos. Teste `tests/v22_keypad.lua`: oito verificacoes de menu, novo jogo, configuracoes, navegacao, compras e selecao de peixes. O smoke nativo do LÖVE permanece no workflow.

**Pendente para 1:1:** fonte bitmap com tabela de larguras completa e telas Java de todos os menus. Os tres atlas de fontes foram recuperados do pacote de engenharia reversa, mas sem as 104 posicoes precisas por fonte. Nao usaremos recortes imprecisos como se fossem oficiais.
