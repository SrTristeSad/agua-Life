# Fase 24 — viewport, seleção e limites gráficos

Esta fase continua a v23 e atua apenas em `ui/retro.lua`/`conf.lua`: a prioridade é a composição do aquário de **240 × 320**, não a adição de novas mecânicas.

## Problemas comprovados

1. O fator de ampliação anterior sempre arredondava para baixo quando era maior que 1. Exemplo: janela 468×858 resultava em *escala 1* e viewport apenas 240×320, quando a largura disponível suporta escala 1,95. Agora a escala não é truncada; continua exatamente 2 em janelas de 480×640.
2. A grade de nado em 240×320 permitia centro X=17 ou X=223; um adulto de 50 pixels não cabia nesses centros. Agora somente a **posição gráfica** é limitada à margem real (corpo/juvenil/alevino). Os valores de simulação, genética e salvamento não mudaram.
3. Na tela de seleção, o exemplar adulto media aproximadamente 39px (50×0,78); a referência fornecida mostra o corpo próximo de 50px. A escala visual foi ajustada para 1 na seleção e 0,85 no aquário comum.
4. O indicador `HEALTH` da referência aparece verde com saúde normal; mudamos para verde, mantendo o vermelho em estado crítico.

## Regressão

`tests/v24_viewport.lua` valida layout em 240×320, 360×620, 468×858, 480×640 e 960×600, hitboxes e geometria de peixes adultos/juvenis, além do fluxo seleção→ações→voltar. Todas as suítes existentes devem permanecer válidas, e as capturas nativas via GitHub Actions devem rodar com os mesmos sprites.

**Ainda pendente:** validação pixel a pixel dos menus originais, imagens de outras telas do J2ME e execução Android. Não afirmar fidelidade 1:1 concluída.
