# Fase 16 — teste nativo do LÖVE em GitHub Actions

Este teste não altera genética, pesquisas, arquivos gráficos nem o salvamento dos jogadores. Ele complementa os testes Lua por simulação com uma execução do binário real **LÖVE 11.x** no GitHub Actions.

## Como funciona

1. O workflow instala `love` e `xvfb` no runner Ubuntu.
2. `FISH_NATIVE_SMOKE=1 xvfb-run -a love .` inicia o **jogo existente** numa tela virtual, com imagens PNG reais e sem carregar ou salvar a partida do jogador.
3. O driver `core/native_smoke.lua` navega usando `love.mousepressed` por aquário, isolamento, vendas, loja, pesquisas e coleção. Por último muda a janela para 960×600 (paisagem).
4. A API oficial `love.graphics.captureScreenshot` grava sete PNGs; cada captura é verificada por `scripts/validate_native_screenshots.py`, incluindo formato, resolução e variedade de pixels, e publicada como artefato do workflow.
5. O teste local `tests/v16_native_driver.lua` simula callbacks desse mesmo driver sem depender do LÖVE instalado.

## Limitações

O runner valida que as telas realmente renderizam no LÖVE e que os cliques de navegação funcionam. Não equivale à inspeção estética por pessoa nem a executar em Android, e a simulação local continua distinta do teste nativo. Quando este ambiente não tiver LÖVE, o resultado do workflow remoto deve ser consultado antes de afirmar que a validação nativa passou.

## Execução local (Linux)

```sh
sudo apt-get install love xvfb
FISH_NATIVE_SMOKE=1 SDL_AUDIODRIVER=dummy xvfb-run -a love .
python3 scripts/validate_native_screenshots.py
```

As capturas são criadas na pasta de dados do LÖVE: `~/.local/share/love/mar_de_isola_lua/native-smoke/`.
