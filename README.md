# agua-Life — matriz original restaurada

**A arte principal voltou à matriz escolhida pelo usuário.** As 441 combinações de corpo e barbatanas e os sete peixes especiais usam os desenhos originais, com suas cores, escamas e formas próprias. A versão vetorial 4K gerada posteriormente foi rejeitada e **não é mais usada no jogo**.

A estrutura em `assets/fish/hd/` permanece somente como arquivo de experimento no repositório e não entra no pacote distribuído. Os saves, DNA, reprodução, doenças, comércio, animação de peixes e o catálogo interativo continuam ativos.

## Qualidade da imagem

O jogo mantém o atlas transparente original em `assets/fish/matrix/atlas_441.png`. A versão de **4032 × 2220 pixels** é gerada do próprio atlas, mantendo os 441 peixes e sete especiais em caixas independentes. O jogo a carrega automaticamente, mantendo cores e silhuetas. A ampliação suaviza serrilhados, mas não recupera detalhes perdidos ou corrige sozinha todos os recortes sobrepostos.

## Como jogar

Instale [LÖVE 11.x](https://love2d.org). Baixe o artefato **agua-Life-Windows-Recorte-Corrigido** da última execução aprovada em [GitHub Actions](https://github.com/SrTristeSad/agua-Life/actions/workflows/lua-tests.yml), extraia-o e abra `INICIAR_WINDOWS.bat`.

- **1/2:** aquários; **3:** loja; **4:** DNA; **5:** coleção; **6:** ateliê.
- **F/H:** alimentar/tratar; **B:** cruzar; **F8/F9:** DNA/necropsia.
- **P:** pausar; **S:** salvar; **Esc:** menu.
- **V:** alternar imagem suave/nítida (somente exibição, não altera o DNA ou arte de origem).
- **F10:** salvar o peixe selecionado como PNG transparente para revisão. O nome inclui C e F; arquivo na pasta de salvamento do LÖVE.

A estrutura de código fica em `game/`, `genetics/`, `art/matrix.lua` e `main.lua`. O projeto de reconstrução `Fish-Tycoon-Lua` original não foi modificado.

## Regenerar atlas fiel

Use `python scripts/refine_original_matrix.py` com Pillow instalado. O gerador usa apenas os pixels já existentes da arte aprovada. Os desenhos vetoriais rejeitados ficam arquivados e não entram no jogo.

## Recortes corrigidos

O erro era uma extração por janela maior do que cada célula, especialmente nas colunas F12/F15/F21. Reextraímos diretamente os 441 peixes da imagem aprovada usando limites entre centros de células, seleção do corpo principal e remoção de ilhas desconexas. O novo `atlas_original_clean_4k.png` substitui o antigo na interface quando disponível. O desenho, a genética e os saves continuam os mesmos.

**Limitação:** a arte original contém sobreposições reais entre barbatanas em algumas linhas. O novo algoritmo remove fragmentos extras, mas não recria pixels que já estavam ocultos na imagem de origem.

## Auditoria visual: problemas que ainda não foram resolvidos

A revisão automatizada de 441 células localizou **67 casos suspeitos** de corte na silhueta (contagem heurística, não diagnóstico confirmado), concentrados principalmente nas colunas F12, F15 e F21. A imagem que originou a matriz já coloca barbatanas de peixes diferentes umas sobre as outras; quando duas ficam sobrepostas, os pixels de uma podem estar totalmente ocultos.

**Não é possível recuperar com fidelidade esses pedaços escondidos apenas com recorte automático ou aumento de resolução.** O plano seguro é corrigir individualmente esses exemplares, com sprites completos da mesma estética, sem refazer os peixes que estão bons.

A rotina `scripts/audit_fish_art.py` gera `quality-review/colunas_em_revisao.png` e `quality-review/relatorio_qualidade.json`. O GitHub Actions publica esses arquivos no artefato **agua-Life-inspecao-dos-441-peixes**.

Ao escolher uma combinação na Coleção, pressione **F10** para exportá-la exatamente como aparece no jogo. A imagem exportada ajuda a indicar quais barbatanas precisam de reconstrução.
