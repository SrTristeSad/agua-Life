# Fase 10 — nado por indivíduo, seleção e catálogo genético

## Continuidade

Trabalho feito sobre `FishTycoonLua_v9` sem substituir o motor, a configuração dos tanques, a genética, a economia, as imagens ou as músicas. Não houve mudança no formato dos dados persistentes: **o esquema de save continua sendo v9**, e os salvamentos v2–v9 continuam sendo tratados pelo mesmo carregador. `mar_de_isola_lua` e `fish_tank_save.json` continuam inalterados.

## Trajetórias e apresentação dos peixes

- Novo módulo puro `ui/swim.lua`: calcula posição e orientação a partir de ID, idade, saúde, doença, posição no tanque e tempo visual. Não consome o RNG de `core/game.lua` e não altera o ritmo de crescimento nem decisões genéticas.
- Movimentos horizontais e verticais suaves, limites fixos no viewport de 420×800 e faixas de nado para 18 peixes. O isolamento recebe duas faixas mais afastadas.
- Filhotes e juvenis usam a direção de nado para espelhar os recortes do atlas; adultos continuam com suas metades esquerda/direita originais.
- Peixes debilitados e doentes nadam mais devagar. Indicadores no tanque sinalizam doença, fome crítica e gestação.
- As trajetórias e indicadores são **decisões visuais da versão Lua**, não reproduções autenticadas dos algoritmos de movimentação do Java original.

## Seleção e interface

- Os alvos dos peixes são resolvidos por distância ao centro, em vez de pela última figura desenhada quando os alvos se sobrepõem.
- Tocar novamente no peixe selecionado agora remove a seleção. A antiga expressão `condicao and nil or valor` jamais retornava `nil` em Lua e impedia esse comportamento.
- Diálogos mantêm precedência sobre a seleção dos peixes.
- A coleção tem uma terceira tela com todas as **21 formas × 21 barbatanas (441 combinações)**. Descobertas reais vêm de `game.s.seen`, já existente, e combinações não registradas continuam ocultas.
- A terceira tela permite percorrer as 21 formas e sinaliza variedades especiais já observadas. A coleção usa os mesmos dados do save antigo e não cria novos requisitos de migração.

## Testes

- Suítes antigas de motor, persistência, interface, ciclo de vida, recursos e performance executadas com `texlua`.
- `tests/v10_swim.lua`: 5 casos cobrindo determinismo, limites dos 18 peixes, isolamento, orientação e velocidades relativas.
- `tests/v10_ui_smoke.lua`: 7 casos cobrindo seleção em diferentes momentos, alvos próximos, alertas, galeria, ciclos de páginas e bloqueio de modal.
- `tests/view_smoke.lua` atualizado apenas para clicar nas coordenadas da nova trajetória visual; lógica de navegação e transferência permanece testada.

## Limites

O port continua experimental: a janela real do LÖVE e o pacote Android ainda requerem teste prático. O movimento visual é novo; não deve ser descrito como fiel ao motor original sem análise adicional do JAR e comparação em emulador. Os recursos extraídos do jogo comercial seguem restritos a estudo/teste local e não podem ser pressupostos como licenciados para distribuição.
