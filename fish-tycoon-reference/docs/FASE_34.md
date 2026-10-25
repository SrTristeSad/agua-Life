# Fase 34 — movimento livre na seleção e estado correto do exemplar

A v33 movia visualmente os peixes comuns para os lados quando se aproximavam da moldura do exemplar selecionado (x=63..119 e y=34..71). Isso fazia o nado mudar de forma artificial ao abrir a ficha. A v34 mantém as trajetórias originais da nossa simulação J2ME, sem alterar nenhum peixe devido à seleção.

Para preservar a legibilidade da moldura, o desenho usa `tanktop.png` do próprio JAR e `love.graphics.setScissor` para recuperar apenas a área de água atrás do exemplar selecionado, antes de desenhá-lo por último. O recorte é convertido da resolução lógica 240×320 para os pixels reais da janela, inclusive em escalas fracionárias. A máscara não adiciona dados ao salvamento, não muda física ou genética e não utiliza novos assets.

Também foi corrigido um caso de seleção órfã: quando um peixe selecionado morre ou é transferido para outro aquário enquanto a ficha está aberta, o jogo limpa o ID e volta à tela do aquário, sem permitir operações acidentais sobre outro destino.

A captura `03-peixe.png` do smoke test utiliza um **Greenfin Fruitfish** adulto de 21 unidades de idade (corpo índice 9, barbatana índice 17). Esse exemplar de teste corresponde ao nome e à idade da referência enviada pelo usuário. O CI inicia uma partida descartável; o fixture não altera a partida do jogador nem a coleção disponível.

## Verificações

- `tests/v34_detail_overlay.lua`: invariância do nado, máscara da moldura, escala fracionária, seleção removida ou transferida, fixture e integridade do formato de salvamento.
- `tests/v30_selection.lua`: regressão atualizada para verificar posições naturais e a ordem de desenho do selecionado, sem exigir deslocamento artificial dos demais peixes.
- Todas as suítes e o workflow gráfico devem seguir aprovados.

**Limite:** o mascaramento usa a textura original do fundo, mas ainda não foi demonstrado que o MIDlet de referência implementava a mesma ordem de composição. Não é uma reconstrução 1:1 definitiva. A validação Android permanece pendente.
