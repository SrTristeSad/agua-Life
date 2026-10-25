# agua-Life — peixes originais em Lua

Reinicio do **agua-Life** como projeto independente **Lua + LÖVE 11.4/11.5**.

**Este commit e uma vitrine de arte**, nao um jogo completo e nem uma copia do Fish Tycoon. O Fish Tycoon serviu apenas de referencia conceitual para combinar formas de corpos e tipos de cauda. Nao reutilizamos seus sprites, PNGs, codigo, musica, paletas, nomes de peixes ou estruturas comerciais.

## Executar no Windows

Instale [LÖVE](https://love2d.org/) 11.4 ou 11.5. Baixe e extraia este repositorio e arraste a pasta inteira para o executavel love.exe; alternativamente, execute love . no terminal na pasta do projeto.

## O que esta pronto

- **21 silhuetas de corpos originais**: proporcao, dorso, volume e curvatura diferentes.
- **21 tipos de cauda**: leques, duplas, flechas, veus, pontas e formas arredondadas.
- **441 combinacoes de corpo e cauda**, 12 paletas e 6 padroes decorativos.
- **Peixes desenhados completamente por codigo**: malhas com sombras interpoladas, raios de barbatanas, pupilas, brilhos e animacao procedural.
- Aquario animado com algas, iluminacao e bolhas igualmente gerados em Lua.
- Galeria de corpos e laboratorio para escolher corpo, cauda, paleta e estampa.
- Nenhum asset externo e necessario para renderizar o jogo.

## Controles

- **Mouse:** selecao dos peixes e botoes do painel.
- **1 / 2:** aquario e galeria.
- **Setas direita/esquerda:** corpo.
- **Setas cima/baixo:** cauda.
- **C:** cor.
- **X:** estampa.
- **Espaco:** pausar a animacao.
- **R:** reiniciar exposicao.
- **F12:** captura de tela em arquivo PNG (apenas saida, sem dependencia grafica).

## Arquivos

- art/catalog.lua — 21 corpos, 21 caudas, 12 paletas e combinacoes.
- art/fish.lua — renderizador vetorial original, sombras, detalhes e animacao.
- main.lua — aquario, apresentacao, escolha de peixe, galeria.
- conf.lua — configuracao do LÖVE.
- tests/ — invariantes e testes do renderizador sem GPU.
- docs/ART_DIRECTION.md — direcao de arte e escopo.

**Ainda nao implementado:** reproducao, alimentacao, economia, pesquisas, persistencia e progressao. Esta e a primeira entrega da nova base e nao substitui um jogo completo.

O codigo antigo Flutter/Dart do agua-Life foi substituido como solicitado. O historico antigo do Git permanece recuperavel.
