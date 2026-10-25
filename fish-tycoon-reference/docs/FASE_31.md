# Fase 31 — trajetórias livres baseadas no bytecode Java original

A interface continua em 240×320. A v30 posicionava os peixes em quatro colunas/linhas artificiais, com oscilação senoidal. Isso diverge da classe Java `m` (Fish Tycoon J2ME 1.0.1): `m.n()` inicializa o movimento de cada objeto em posições aleatórias e velocidades independentes, armazenadas na classe `h` como inteiros fixos 16.16. `h.c(int)` integra posição/velocidade e `h.a(int,int,int,int,int,int,boolean)` modifica velocidade e orientação.

## Implementação

- `ui/j2me_motion.lua` calcula trajetórias independentes para cada peixe usando o ID como semente **somente visual**. A idade de alevino utiliza velocidades lentas; adultos usam os valores em 16.16 visíveis no método `m.n()` (20.000±15 horizontal e 6.380±15 vertical, em unidades fixas por atualização).
- A taxa de conversão adotada foi 60 atualizações visuais por segundo; **não confirmamos ainda o frame rate real do MIDlet**, logo o ritmo é uma aproximação apoiada nos números do Java, não uma cópia perfeita.
- A posição inicial ocupa a área aberta do tanque, sem grade de quatro colunas. Direções são refletidas nas bordas. A distribuição não altera a ordem ou as propriedades dos peixes no motor.
- `ui/retro.lua` usa o novo renderizador apenas nas telas clássicas; mantém o isolamento e a âncora de seleção da captura J2ME. `ui/swim.lua` permanece intacto como base de regressão da interface antiga.
- `tests/v31_motion.lua` confere limites, velocidades, inversão, variação dos centros, independência do índice e ausência de chamadas ao RNG biológico. O teste nativo ganhou a captura `20-nado-livre` com 18 peixes.

## Limites da fidelidade

A posição/velocidade do MIDlet dependem de sorteios e do estado interno persistido, ausentes no salvamento do port. O visual reproduz a **estrutura** de movimento, não os números exatos de uma sessão original. Nenhuma imagem, música, regra econômica, genética ou formato de save foi modificado. O Android e uma comparação quadro a quadro com MIDlet executado permanecem pendentes.
