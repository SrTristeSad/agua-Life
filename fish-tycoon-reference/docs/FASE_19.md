# Fase 19 — apresentação original como prioridade

## Referências

As imagens fornecidas mostram o Fish Tycoon J2ME em **240×320**, com arte azul de aquário, peixes com sprites originais, barra superior roxa de pequenos ícones, navegação inferior FISH/MENU ou SELECT/BACK e recipiente azul de isolamento. Não foram fornecidas capturas de todas as telas: esta etapa é uma **primeira reconstrução visual**, não uma alegação de completude 1:1.

## Implementação

- Novo `ui/retro.lua` em 240×320, tela padrão no `main.lua`; preservado `ui/view.lua` para testes comparativos.
- Navegação: inicial (Continue/New Game/Options/About), aquário, detalhes do peixe, ações, mover, tratar, loja, pesquisa, coleção e configurações.
- Motor v18 e saves v9 inalterados. O jogador pode criar outra partida sem editar arquivos, com confirmação e salvamento arquivado.
- Artes: fundos/peixes já versionados, mais `splash.png`, `assets.png`, `gameMenuTank.png` obtidos do JAR enviado. Os três recursos comerciais novos são opcionais no checkout público; `scripts/import_j2me_assets.py` os importa do JAR de quem possui o jogo. O pacote `.love` de teste os inclui.
- O teste `tests/v19_retro.lua` cobre novo jogo, seleção, navegação, falhas de escrita e barras laterais. O teste nativo `core/retro_smoke.lua` gera PNGs de sete telas.

## Ainda não concluído

Recorte e fonte 100% fiéis do atlas, funcionamento de todas as telas do original (não disponibilizadas), equipamentos exatamente como no Java, sprites e posições de todos os menus. As configurações de velocidade e pesquisa continuam adaptações documentadas. Não há emulador Android validado.

## Correções de acesso às mecânicas

O tanque de isolamento expõe `BREED` na tecla inferior esquerda e o tanque de vendas expõe `OPEN/CLOSE`, mantendo `FISH/MENU` no tanque principal. As configurações de música são preservadas no save sem alterar seu número de versão.
