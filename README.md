# agua-Life — base jogável 0.1 (Lua + LÖVE)

Aquário original com **criação de peixes, DNA combinável, dinheiro, comida, remédios, doenças, reprodução, nascimento, vendas e salvamento**. Funciona em Windows, Linux e plataformas compatíveis com **LÖVE 11.x**. Não usa WebView, Flutter ou servidor externo.

O objetivo visual é a matriz **21 corpos (C1–C21) × 21 caudas/barbatanas (F1–F21) = 441 combinações**. A arte é original, inspirada no princípio modular de criação de peixes, sem reutilizar sprites comerciais no jogo novo. Cor e estampa acrescentam variações.

## Jogar

1. Instale [LÖVE 11.x](https://love2d.org).
2. Na página [Actions > Lua tests](https://github.com/SrTristeSad/agua-Life/actions/workflows/lua-tests.yml), abra a execução mais recente com status **verde** e baixe o artefato **agua-Life-playable**.
3. Extraia o ZIP. Abra **agua-Life-playable.love** com o LÖVE (duplo clique após associar a extensão ou comando love agua-Life-playable.love).
4. Na tela inicial, clique em **NOVA PARTIDA**. Nas próximas visitas, use **CONTINUAR**.

Também é possível baixar este repositório e rodar a pasta diretamente usando love .; no Windows, pode usar INICIAR_WINDOWS.bat.

### O que já dá para jogar

- **Quatro peixes iniciais**, sendo três adultos para cruzar imediatamente.
- **Ração** para manter os peixes alimentados, **remédios** contra fungos e íctio.
- **Cruzamento de dois adultos**: escolhe um peixe, ativa Cruzar e clica no segundo. Filhote nasce após **4 ciclos** (24 segundos com o jogo rodando).
- **DNA herdável**: dois alelos por gene; o filhote manifesta uma combinação intermediária de **corpo, cauda, cor e estampa**, e mantém os alelos herdados para futuros cruzamentos.
- **Dinheiro**: venda peixes adultos e compre ração, medicamentos, ovos e melhorias.
- **Aquário 2**: desbloqueável na loja, com capacidade para 14 peixes (14 no primeiro também).
- **Pesquisa de cuidado**: três níveis de melhora na recuperação.
- **Doenças, fome, envelhecimento e morte**; necropsia indica uma **causa provável**, não um diagnóstico definitivo.
- **Coleção de 441 combinações** em matriz visual C×F, com destaque para descobertas.
- **Sete combinações raras** com valor maior.
- **Salvamento automático**, save manual, backup e arquivo da partida antiga ao iniciar uma nova.
- **Ateliê** do peixe Azul-Rubi com peças PNG independentes, nadadeiras animadas e marcas de articulação.

### Controles

| Tecla | Ação |
|---|---|
| Mouse | Selecionar peixes e botões |
| 1 / 2 | Aquário principal / viveiro |
| 3 / 4 | Loja / Laboratório de DNA |
| 5 / 6 | Coleção 21×21 / Ateliê |
| F | Alimentar peixe selecionado |
| H | Tratar peixe doente |
| B | Iniciar cruzamento; depois clicar em outro peixe adulto |
| F8 / F9 | Exame de DNA / necropsia |
| P ou Espaço | Pausar a simulação |
| J | Ver juntas da animação modular |
| S | Salvar |
| Escape | Fechar janela, cancelar seleção de parceiro ou voltar ao menu |

A loja, o laboratório e todas as telas têm botões para utilizar a interface sem teclado.

## Corrigir erro de caminho no Windows

Caso o LÖVE exiba `Cannot load game at path '...agua-Life-main"'`, isso era causado pelo iniciador antigo: `%~dp0` termina em barra invertida e era passado ao LÖVE com aspas que podiam virar um caractere literal no caminho. O iniciador foi corrigido para usar `%~dp0.` (caminho normalizado, sem barra final) e também abrir um `.love` caso esteja ao lado do BAT.

**Se você já tem a pasta antiga:** atualize somente o arquivo `INICIAR_WINDOWS.bat` a partir deste repositório e execute-o novamente. Alternativamente, com LÖVE instalado, arraste a pasta que contém `main.lua` sobre `love.exe`, ou execute no terminal `love .` de dentro dessa pasta.

Existe também um teste automatizado no GitHub Actions, em `windows-launch-smoke.yml`, que verifica caminhos com espaços e arquivos `.love` num Windows real.

## Arquitetura

- **main.lua** — telas e interações do cliente.
- **game/play.lua** — simulação, economia, reprodução, morte e progressão sem dependência de LÖVE; testes determinísticos.
- **game/storage.lua + game/json.lua** — gravação JSON com validação, backup e arquivamento da partida anterior.
- **genetics/dna.lua + genetics/health.lua** — expressão genética e fisiologia.
- **art/fish.lua** — 21 silhuetas procedurais × 21 barbatanas, cor e padrão.
- **art/rigged_fish.lua + assets/fish/azul_rubi/** — arte do Azul-Rubi em 12 camadas RGBA, animada pelo motor.
- **fish-tycoon-reference/** — cópia separada para estudo, não utilizada nem incluída no pacote .love distribuído.

## Desenvolvimento e testes

A integração roda no GitHub Actions, incluindo testes puros em Lua, validação dos PNGs transparentes e renderização real em LÖVE sob X virtual.

Com Lua 5.4: lua tests/game_play.lua && lua tests/genetics.lua.
Com LÖVE 11.x: love .

**Status:** base jogável funcional, não um clone 1:1 completo do Fish Tycoon. Os 441 peixes do catálogo são atualmente desenhados por uma combinação procedural de corpos e caudas, e apenas o **Azul-Rubi** tem sprite HD modular próprio. Ainda faltam melhorias de animação dos demais corpos, som, múltiplos cenários e maior profundidade nas pesquisas.
