# Fase 25 — barra superior e controles J2ME

A reconstrução visual permanece em 240 × 320. Comparação com as capturas recebidas: o original mantém três miniaturas de tanque mais estreitas à esquerda, o destaque amarelo do peixe selecionado, as etiquetas «For Sale!» dos adultos anunciados, e comandos inferiores SELECT/BACK.

## Mudanças

1. `ui/retro.lua` desenha e registra a barra em 11 intervalos inteiros: `[0,18,36,54,77,100,123,146,169,192,216,240]`. A soma cobre exatamente 240px, sem gaps de toque.
2. Hitbox de cada peixe leva em conta corpo adulto de 50px, juvenil e alevino. A visualização mantém um alvo mínimo para facilitar toques e escolhe o exemplar mais próximo em sobreposições.
3. Etiquetas «For Sale!» aparecem em adultos do tanque de venda tanto na tela geral quanto em detalhe.
4. F1/F2 ativam as softkeys exibidas na parte inferior; o botão oculto/desabilitado não executa ações.
5. Novo teste `tests/v25_controls.lua`; nenhum save ou dado do motor foi alterado.

## Validação e limites

A suíte de teste executa a interface em Lua com API gráfica simulada. A execução nativa deve ser confirmada no GitHub Actions. Ainda não existe comparação pixel a pixel com todas as telas do MIDlet e não se considera reconstrução 1:1 concluída.