# Fase 14 — renderização e interação

## Origem e escopo

Continua a implementação Lua v13 sem refazer o motor. O JAR e os sprites continuam como referência de estudo, e as fórmulas experimentais não foram alteradas.

## Correções

1. **Isolamento:** `Assets:tankBackground` agora prioriza `assets/original/isolation_tank.png` quando a sala é `isolation`; a imagem é dimensionada preservando a proporção 98:46 e centralizada em uma área que engloba os dois peixes. As outras salas mantêm seus cenários (`tank1`, `tank2` e `tank3`).
2. **Elipse:** removido valor `0.4` como contagem de segmentos; usa 16 segmentos inteiros. Corrige desenho fallback quando recursos gráficos estiverem indisponíveis.
3. **Foco de modal:** atalhos 1–4 e espaço não operam atrás das janelas modais; Esc/Voltar fecham as janelas. Fora delas, trocar de tela por teclado limpa a seleção para corresponder à navegação pelo rodapé.

## Testes efetivos

- Todas as 26 suítes da árvore `tests/` executadas via `texlua` em 24/10/2026, sem falhas.
- Nova suíte `tests/v14_render.lua`: carrega cabeçalhos dos PNGs reais, confere limites de recorte com dimensões reais, desenha com API simulada as 441 combinações adultas nas duas orientações, os 21 juvenis e filhotes, e todos os ambientes/páginas/modais. Também simula redimensionamento para diferentes tamanhos e confere bloqueio de atalhos modais.
- O LÖVE nativo **não está instalado neste ambiente**: a abertura de janela, o compositor final, os áudios e os controles no aparelho ainda precisam de validação real.
- `TESTAR_LUA.bat` atualizado para incluir a nova suíte.

## Limitações e próxima prioridade

A renderização baseada em mocks não detecta necessariamente todas as diferenças de composição do LÖVE. Validar o `.love` em LÖVE 11.4 num desktop, conferir texturas e toque num Android e aprofundar o bytecode em pesquisas/genética. Não redistribuir os assets originais comercialmente sem direitos apropriados.
