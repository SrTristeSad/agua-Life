# agua-Life — matriz original restaurada

**A arte principal voltou à matriz escolhida pelo usuário.** As 441 combinações de corpo e barbatanas e os sete peixes especiais usam os desenhos originais, com suas cores, escamas e formas próprias. A versão vetorial 4K gerada posteriormente foi rejeitada e **não é mais usada no jogo**.

A estrutura em `assets/fish/hd/` permanece somente como arquivo de experimento no repositório e não entra no pacote distribuído. Os saves, DNA, reprodução, doenças, comércio, animação de peixes e o catálogo interativo continuam ativos.

## Qualidade da imagem

O jogo mantém o atlas transparente original em `assets/fish/matrix/atlas_441.png`. A versão aperfeiçoada, gerada do próprio atlas sem redesenhar nenhuma espécie, será usada apenas quando existir em `assets/fish/matrix/atlas_original_refined_4k.png`. A ampliação preserva o desenho aprovado, mas não recupera detalhes perdidos no original pequeno.

## Como jogar

Instale [LÖVE 11.x](https://love2d.org). Baixe o artefato **agua-Life-Windows-original** da última execução aprovada em [GitHub Actions](https://github.com/SrTristeSad/agua-Life/actions/workflows/lua-tests.yml), extraia-o e abra `INICIAR_WINDOWS.bat`.

- **1/2:** aquários; **3:** loja; **4:** DNA; **5:** coleção; **6:** ateliê.
- **F/H:** alimentar/tratar; **B:** cruzar; **F8/F9:** DNA/necropsia.
- **P:** pausar; **S:** salvar; **Esc:** menu.

A estrutura de código fica em `game/`, `genetics/`, `art/matrix.lua` e `main.lua`. O projeto de reconstrução `Fish-Tycoon-Lua` original não foi modificado.
