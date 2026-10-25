# Fish Tycoon Lua — v72: ciclo biologico na ordem do JAR

## Versao 72 — crescimento, condicao, doenca e alimentacao

A auditoria do metodo Java `n.a(o)` confirmou que cada
peixe passa pela rotina de condicao `n.c(m)`, pela de
risco de doenca `n.a(m,int)` e, somente depois, pela de
alimentacao `n.a(m,boolean)`.

O Lua processava alimentacao primeiro. Uma queda de comida no
ciclo atual podia reduzir precocemente a condicao de peixes
que antes do ciclo ainda tinham cinco unidades de comida.

- **Ordem corrigida:** calcula condicao/saude, verifica
  infeccao e depois reduz a reserva alimentar, preservando as
  penalidades de fome extras do port Lua calculadas com o estoque
  existente **antes** da alimentacao.
- **Comida no nivel inicial:** no Java a pesquisa de comida
  nivel 1 decrementa a reserva **diretamente**, sem chamar RNG.
  O port consumia desnecessariamente um `j.c(100)` para
  todos os peixes, a cada ciclo. Agora o RNG alimentar somente
  e consumido nos niveis seguintes, com limiares `<=60`
  e `<=30`. O quarto nivel continua uma adaptacao Lua.
- **RNG dos equipamentos:** no Java `n.c(m)` verifica
  `b.d(10)` (aerador) antes de `b.d(9)`
  (aquecedor); esta ordem foi respeitada.
- **Testes:** `tests/v72_food_cycle_order.lua` cobre
  ausencia de sorteio no nivel inicial, sequencia de sorteios
  nas pesquisas, limite alimentar de cinco unidades,
  planta nutritiva e 12 linhas do tempo deterministicas.
  `tests/v71_disease_rng.lua` foi atualizado para a ordem
  Java e continua cobrindo 144 cenarios de sementes.
  
**Limites:** as penalidades adicionais de fome e algumas
bonificacoes por equipamento continuam adaptacoes declaradas do
port Lua. A versao 72 corrige as chamadas e a sequencia
biologica comprovadas, mas nao afirma que todos os valores
de saude e fome sejam 1:1 com o MIDlet.
O algoritmo de RNG de 48 bits da v70 e a leitura dos saves
anteriores permanecem compativeis.

## Historico anterior


## Versao 71 — risco de infeccao, planta de cura e caracol

A auditoria do metodo `n.a(m,int)` do JAR original identificou
duas diferencas na rotina de infeccao do port Lua:

- **Sorteio de doenca:** o Java utiliza `j.c(10000)`, e o numero
  e sorteado **antes** de verificar o equipamento caracol.
  A implementacao anterior sorteava o caracol antes e usava
  `game:random()*10000` para o risco. Mesmo com o RNG de
  48 bits da v70, essa formula gerava um valor diferente da
  `nextInt(10000)` do Java, deslocando os resultados.
- **Planta e caracol:** no bytecode, os efeitos sao alternativos.
  Com planta de cura ativa, a chance de doenca e dividida por
  dois imediatamente e a rolagem do caracol nem acontece.
  Sem planta, o caracol pode reduzir o risco pela metade com
  `j.c(100)<=49`. Anteriormente o port aplicava os dois
  bonus em sequencia e reduzia o risco duas vezes.

A nova ordem e `j.c(10000)` para doenca, depois
`j.c(100)` do caracol somente quando a planta nao estiver
ativa, e por fim `j.c(2)` para classificar a infeccao, se
necessario. Peixes que ainda nao sao adultos, ou ja estao
doentes, nao executam esse sorteio de risco.

A suite `tests/v71_disease_rng.lua` compara limites,
equipamentos, consumo de chamadas e 144 cenarios de seeds
com a implementacao independente de `nextInt` da v70.
Os antigos testes `v18_contagion` e `v7_regression`
foram atualizados para a forma inteira original.

**Compatibilidade:** novas partidas usam o RNG Java da v70.
Salvamentos antigos continuam usando Park-Miller; esta
correcao muda a ordem das chamadas da rotina de doenca
tambem nesses saves, mas nao os converte de algoritmo.
Nao houve alteracoes na UI, nos sprites ou na genetica.
A compatibilidade 1:1 do restante da simulacao ainda
precisa ser auditada.

## Histórico anterior


## Versao 70 — gerador original, sem quebrar saves antigos

O arquivo `j.class` do JAR fornecido confirma que o Fish Tycoon
utiliza um gerador LCG de **48 bits**, com o algoritmo de
`java.util.Random`:

- Estado inicial: `(seed XOR 25214903917) mod 2^48`.
- Atualizacao: `(estado * 25214903917 + 11) mod 2^48`.
- `j.b(bits)`: devolve os bits mais altos do estado atualizado.
- `j.c(n)`: em limites que sao potencias de dois, utiliza
  multiplicacao por `next(31)`; nos demais, utiliza rejeicao
  para impedir vieses decorrentes de overflow de inteiros Java.

`core/j2me_random.lua` executa as contas com duas metades
de 24 bits, em vez de multiplicar diretamente numeros de 48 bits.
Isso preserva exatidao no Lua 5.1/LuaJIT e 5.4, sem requerer
dependencias ou operacoes bitwise de 64 bits.

**Compatibilidade:** novas partidas armazenam
`rng_kind='j2me48'` e um estado de ate 48 bits em `rng`.
Salvamentos anteriores ao v70, que nao possuem `rng_kind`,
continuam usando o antigo Park–Miller e nao sao resemeados.
O formato de save permanece na versao 9.

`core/j2me_spawn_rng.lua` agora separa as quatro chamadas
`j.c(n)` para movimento da ultima chamada `j.b(16)`
do construtor de peixe. A v69 ainda confundia `j.b(16)`
com `j.c(65536)`, produzindo valores diferentes.

**Validacao:** `tests/v70_j2me_random.lua` compara vetores
de quatro sementes contra uma execucao independente OpenJDK,
verifica `nextBits(16)` inclusive com seed negativa,
serializacao e continuacao apos recarregar, rejeicao
de estado/algoritmo invalido e continuidade exata do RNG antigo.

**Limites:** a sequencia do Java foi reproduzida para as
chamadas conferidas. Isso nao significa que cada rotina do
motor (doencas, mercado, graficos e pesquisas) ja tenha
a mesma ordem de chamadas do MIDlet. O seed inicial e os
demais eventos do Java ainda exigem auditoria 1:1.
Nao prometer reproduzir retroativamente a sequencia Java
em partidas criadas no gerador Lua anterior.

## Historico de versoes anteriores


## Versao 69 — consumo de RNG do construtor J2ME

Foi verificado o bytecode `m.a(IIIII)` e o construtor auxiliar
`m.a(IIIIIIIIIIIIIJ)` do JAR de 2007. Ao criar um peixe, o Java
consome **cinco chamadas de RNG** para definir atributos visuais e
de movimentacao, antes de quaisquer calculos seguintes do mercado:

1. `j.c(190)` — posicao horizontal de entrada;
2. `j.c(39)` — posicao vertical de entrada;
3. `j.c(1)` — direcao horizontal (tambem avanca o RNG);
4. `j.c(1)` — direcao vertical (tambem avanca o RNG);
5. `j.b(16)` — deslocamento extra de movimento.

O nucleo Lua anterior nao consumia esses sorteios e, portanto,
alterava a ordem de futuras chances de venda, doença e mutacao.
`core/j2me_spawn_rng.lua` registra a ordem recuperada, e
`Game:addFish` a consome **apos** validar capacidade, corpo, cauda
e genes e **antes** da primeira cotacao de mercado para adultos.

- Sorteios cosmeticos de sexo continuam removidos, conforme a v66.
- Uma criacao recusada nao consome RNG nem altera o proximo ID.
- Filhotes extras de uma mesma gestacao consomem cinco chamadas
  de geracao visual *por peixe*, mantendo uma unica rolagem de
  mutacao genetica compartilhada pela gestacao.
- `tests/v69_j2me_spawn_rng.lua` valida a ordem, a quantidade
  e os limites das chamadas, as rejeicoes atomicas, as
  cotacoes e os saves.
- Os testes v15, v66, v67 e v68 foram adaptados para distinguir
  RNG visual de RNG de mutacao.

**Limitacao tecnica conhecida:** o Java utiliza um LCG de 48 bits
(`j.b`/`j.c`); o nucleo atual Lua ainda utiliza Park–Miller.
Esta etapa reproduz o **numero e a ordem das chamadas**, nao a
mesma sequencia numerica de um seed Java nem as coordenadas
visuais exatas dos peixes. Fazer a migracao do algoritmo exige
um esquema de save compativel, sem destruir partidas existentes.
Os resultados de partidas novas/continuadas podem mudar com
esta correcao de RNG, embora os saves permaneçam legiveis.

## Historico das versoes anteriores


## Versao 68 — sorteios de mutacao no nascimento

Analise direta do metodo Java `n.a(m,o,int)` no JAR
`Fish_Tycoon_240x320-111845-mobiles24.jar`.

- **Chance da mutacao:** o efeito do sexto peixe especial usa
  `j.c(100)<=15` (16 em 100 resultados possiveis).
- **Parte alterada:** `j.c(100)<=49` seleciona a barbatana
  do parceiro armazenada em `m.g[5]`; caso contrario, o corpo.
- **Direcao correta:** em indices internos (0..20 no Java), o
  sorteio `j.c(100)<=49` aumenta o indice; caso contrario, diminui.
  O Lua anterior usava um sorteio de duas possibilidades e aplicava
  a direcao inversa para um dos resultados.
- **Limites importantes:** no indice 0 (equivalente ao 1 do Lua),
  o Java consome uma rolagem de direcao mesmo quando obriga +1.
  No indice 20 (21 do Lua) nao consome essa rolagem e obriga -1.
  Corrigir esse numero de chamadas preserva a ordem dos sorteios
  que acontecem depois na simulacao.
- **Irmaos:** o parceiro sofre a mutacao uma so vez antes da
  criacao dos filhotes adicionais. Os irmaos compartilham a
  mesma variedade resultante.
- **Regressao:** `tests/v68_j2me_mutation_rng.lua` usa sorteios
  controlados para verificar limiares, corpo, barbatana, limites,
  numero de chamadas e gestacao com dois filhotes. O antigo
  `tests/v15_jar_genetics.lua` foi atualizado para a quantidade
  de sorteios comprovada pelo bytecode.

Nao houve mudancas na interface, tabela de preços, formula de
media inteira, tempo de gestacao ou capacidade dos tanques.
Acorrecoes da sequencia de RNG podem alterar resultados futuros
de partidas existentes, embora salvamentos validos continuem
compativeis. O motor ainda nao e uma replica integral do Java.

## Versoes anteriores


## Versao 67 — integridade dos descendentes

Nesta etapa foi aprofundada a analise de `m.a(IIIII)` no JAR J2ME,
que confirma os indices expressos da variedade de um filhote pela
media inteira dos indices dos dois pais.

- **Criacao com alelos invalidos:** `Game:addFish` rejeita tabelas de
  genes malformadas, indices fora de 1..21, numeros fracionarios e
  estruturas incompletas *antes* de consumir RNG, ID ou espaco do tanque.
- **Leitura de salvamentos:** `Game.fromTable` rejeita metadados
  geneticos incoerentes e permite recuperar o backup, em vez de
  propagar um estado que poderia quebrar a reproducao.
- **Genomas independentes:** cada peixe recebe somente os campos
  geneticos esperados (`body`, `tail`, `mutated`), clonados.
  Entradas ciclicas ou campos extras nao entram no estado do jogo.
- **Regressao:** `tests/v67_genetics_schema.lua` verifica a
  atomicidade dos erros, isolamento dos genes, preservacao do
  salvamento, fallback de backup e media inteira dos pais.

A matematica hereditaria (media inteira) foi mantida. O esquema
`genes` e metadado de compatibilidade do port Lua: nao substitui
uma recriacao completa dos atributos internos da classe Java.
Nao se considera concluida a equivalencia integral de RNG,
mutacoes ou outras mecanicas.

## Historico — v66 e anteriores


## Versao 66 — dois problemas da criacao e reproducao

O JAR original guarda o peixe na classe `m.class`, sem um campo
independente de sexo. O port Lua tem uma etiqueta de sexo para
apresentacao, mas nao exige sexos diferentes para reproduzir.

- **Sorteio cosmetico que alterava o gameplay:** `Game:addFish` usava
  `self:random()` para escolher a etiqueta M/F. A chamada consumia
  um numero do gerador de jogo e deslocava a ordem dos sorteios
  de mercado, doencas e mutacoes. A etiqueta agora usa a paridade
  do ID, como o carregador ja fazia para peixes antigos.
  O RNG so muda quando uma operacao de gameplay exige sorteio.
- **Tabelas geneticas compartilhadas:** ao adicionar peixes com uma
  tabela de genes recebida como argumento, o motor podia manter a
  referencia original. Modificacoes posteriores nessa tabela podiam
  alterar genes de peixes ja criados. Cada peixe agora guarda
  sua propria copia da estrutura genetica.
- **Regressao:** `tests/v66_cosmetic_rng.lua` compara 160 cenarios
  de sorteios e crescimento com etiquetas implicitas/explicitas,
  verifica recarregamento dos saves e independencia de genes
  entre criacoes sucessivas.

Nao foram modificados os indices de corpo/barbatana, duracao de
gestacao, probabilidades de mutacao, formulas de preco nem a interface.
Como a sequencia de RNG foi corrigida, **partidas novas podem ter
resultados aleatorios diferentes dos da versao 65**; saves antigos
continuam sendo lidos e mantem o estado RNG que ja foi salvo.
Ainda existem diferencas do port Lua em relacao ao JAR, portanto
esta etapa nao comprova fidelidade funcional completa.

## Historico de versoes anteriores


## Versao 65 — fila de ovos e precos inteiros

Auditoria do nucleo Lua sobre as operacoes que mudam simultaneamente
o numero de peixes, o saldo em dinheiro e o estado persistido.

- **Ovos comprados em espera:** quando havia varios ovos prontos e
  poucas vagas no tanque 1, `Game:_events()` percorria a lista ao
  contrario e fazia o ovo mais recente nascer primeiro. Agora a fila
  respeita a ordem em que os ovos foram comprados; apenas os ovos
  efetivamente nascidos sao removidos da lista, sem pular os seguintes.
- **Lotacao e morte no mesmo ciclo:** se o tanque esta cheio, um ovo
  aguarda vaga. Se um peixe morre no ciclo em que o ovo esta pronto,
  o nascimento acontece uma unica vez depois da liberacao da vaga.
- **Preco fracionario corrompia o save:** `Game:changePrice` aceitava
  ajustes como +2.5 e `Game:sell` registrava receita decimal;
  `stats.earned` exige inteiro na validacao e a partida nao podia
  mais ser salva. Agora ajustadores de preco aceitam somente inteiros,
  `sell` recusa valores invalidos antes de remover o peixe e o
  carregador recusa valores de saldo/preco fracionarios em saves v9.
- **Testes:** `tests/v65_birth_queue.lua` verifica a fila, a
  recuperacao de ovos que aguardam vaga, a morte simultanea e
  simulacao identica em um passo ou segundo a segundo.
  `tests/v65_price_integrity.lua` verifica venda, renda, saldo
  e integridade dos saves mesmo apos pedidos invalidos.

Esta versao nao altera os preços originais dos peixes, probabilidades,
genes, capacidade de 18 lugares nem o tempo dos ovos. A regra FIFO
evita que ovos mais novos ganhem prioridade quando o tanque esta cheio.
Os testes nao comprovam equivalencia integral com o JAR original.

## Historico — v64 e anteriores


## Versao 64 — transicoes de gestacao, morte e eventos

Auditoria baseada no bytecode `n.a(o)` do JAR Fish Tycoon J2ME
original, preservando as regras de capacidade e os valores existentes.

- **Nascimento na mesma atualizacao da morte:** no Java a gestacao
  e resolvida antes da deterioracao da condicao do peixe. A versao
  Lua anterior eliminava a mae antes da eclosao, perdendo os filhotes.
  `core/game.lua` agora processa a eclosao apos o incremento de
  idade e antes de `Care.step`.
- **Capacidade preservada:** o tanque principal permanece limitado
  a 18 peixes. Se estiver cheio, a incubacao natural nao produz
  filhotes; os ovos comprados continuam aguardando vaga, como antes.
- **Tempo fracionario:** chamadas repetidas com `dt=0.1` ou
  `dt=1/60` acumulavam desvios que atrasavam uma eclosao para
  depois de uma visita do mercado, alterando a sequencia de sorteios
  e ate o sexo de um peixe. `core/sim_clock.lua` normaliza apenas
  fronteiras proximas a segundos inteiros, sem arredondar cada frame.
  `core/game.lua` e `core/market.lua` compartilham essa regra.
- **Testes automatizados:** `tests/v64_birth_death_order.lua`
  cobre morte da mae, nascimento, tanque cheio e ovos aguardando vaga.
  `tests/v64_fractional_clock.lua` exige igualdade de estado entre
  1.200 segundos simulados em um passo, atualizacoes de 0.1 segundo
  e 72.000 frames de 1/60 de segundo em seis cenarios com mercado,
  pesquisas e ovos.

A fase nao modifica os precos, a genealogia dos peixes, os
coeficientes biologicos ou a interface. O projeto ainda nao esta
visualmente ou funcionalmente igual ao Java em todos os aspectos.

## Historico de versoes anteriores


## Versao 63 — integridade dos recipientes e teste de longa duracao

Na revisao do carregador foi confirmado um caso ainda sem protecao:
um array JSON vazio `[]` podia ser substituido por um objeto vazio
`{}` e ser interpretado como lista vazia em Lua. Em um tanque,
isso poderia esconder a perda de peixes e impedir a recuperacao do backup.

- `core/json.lua` preserva o tipo de recipiente (`array` ou `object`)
  vindo de JSON, inclusive quando vazio. Uma serializacao seguinte
  mantem `{}` como objeto e `[]` como lista.
- `core/game.lua` rejeita objetos JSON em campos que sao listas de
  peixes, ovos, eventos e historico do mercado. Tabelas Lua criadas
  normalmente pelo proprio jogo continuam aceitas.
- `tests/v63_json_container_integrity.lua` comprova que a alteracao
  de um tanque com peixes para `{}` provoca rejeicao do save e
  recuperacao da copia de seguranca.
- `tests/v63_core_stress.lua` realiza 1.700 operacoes variadas em
  20 partidas deterministicas, verificando reabertura dos saves
  durante as partidas, integridade de dinheiro e peixes e equivalencia
  entre simulacao em um unico passo e incrementos de um segundo.

Esta etapa **nao altera** mecanicas biologicas, economia, artes nem
menus. Os testes de integridade impedem alguns modos de perda
silenciosa, mas nao garantem fidelidade 1:1 ao JAR Java ou ausência
de outros bugs. Antes de instalar esta versao, preserve uma copia de
seus arquivos de salvamento.

## Histórico anterior


## Versao 62 — corrupcao silenciosa e seguranca do save

Uma auditoria da v61 reproduziu seis categorias de dados corrompidos
que o carregador v9 ainda aceitava e corrigia silenciosamente.
A versao 62 endurece o contrato de serializacao e recuperacao:

- Estatisticas `treatments`, `failed_treatments`, `mutations`,
  `infections` e demais contadores da v9: nenhum valor invalido sera
  transformado automaticamente em zero.
- Estoque `supplies.mutagen` invalido agora rejeita o salvamento.
- Entradas malformadas de `market.history` e `market.last_visit`
  nao sao apagadas silenciosamente; `Storage.load` tentara o backup.
- O parser JSON agora rejeita chaves duplicadas em objetos, evitando
  que um segundo campo `tanks`, `stats` ou `cash` substitua o anterior.
- **Verificacao antes de gravar:** `Storage.save` serializa e reabre
  uma copia do estado para validacao. Se a nova partida nao puder ser
  carregada, a gravacao e interrompida ANTES de substituir o principal
  ou o backup, e o relogio persistido e restaurado.
- Migracoes v2-v8 continuam tolerando contadores introduzidos em
  versoes recentes que nao existiam nos formatos legados.

Os testes `tests/v62_save_contract.lua` verificam recusas de save
corrompido, recuperacao via backup e gravações validas. A suite
`tests/v62_timeline_equivalence.lua` compara avancos simulados em
passo unico com avancos segundo a segundo, incluindo mercado,
reproducao, ovos e pesquisas; os cenarios devem convergir.

Estas correcoes focam **integridade e persistencia**, nao alteram
genetica, preco base, sprites nem o menu. Um backup pode conter um
progresso anterior; nao e possivel recuperar automaticamente dados ja
apagados por versoes antigas.

## Historico de versoes anteriores

# Fish Tycoon Lua — v61: auditoria de integridade do nucleo

## Versao 61 — correcoes graves do estado de jogo e salvamentos

Esta etapa priorizou bugs reproduziveis de perda de progresso, sem alterar a
aparencia nem a tabela de valores do Fish Tycoon Java:

- **Arrays com null no JSON:** `[peixe,null,peixe]` era compactado pelo
  parser e podia carregar uma partida com peixes desaparecidos. Agora o
  arquivo e rejeitado, permitindo o uso do backup anterior.
- **Tanques e ovos com estrutura incorreta:** objetos JSON com chaves
  `"1"`, `"2"` podiam passar por listas vazias. A verificacao do save
  exige listas densas para peixes, ovos, eventos e historicos.
- **Relogio invalido:** `Game:advance(math.huge)` antes simulava 24h
  e no teste matou todos os peixes; NaN e infinitos agora sao ignorados.
- **Contadores de saves v9 corrompidos:** idade acumulada negativa,
  intervalo de crescimento invalido e contadores do mercado nao sao
  mais silenciosamente normalizados. O loader tenta o backup.
- **Entrada de peixes e precos:** idade infinita e ajuste NaN de valor
  sao recusados antes de modificar RNG, peixes ou dinheiro.

Os cenarios sao cobertos por `tests/v61_core_integrity.lua`, incluindo
recuperacao do backup e comparacao do estado antes/depois de entradas
invalidas. Os testes de genetica, crescimento, loja e reproduçao
continuam na suite de regressao.

**Importante:** o progresso recuperado de um backup pode ser anterior
ao ultimo salvamento; arquivos ja perdidos antes desta correcao nao
podem ser reconstruidos automaticamente. A versao 61 nao resolve
todas as diferencas biologicas ou economicas entre o port Lua e o JAR.

## Historico de interface

# Fish Tycoon Lua — v60: menu WELCOME com rolagem J2ME (240 × 320)

## Versao 60 — janela de cinco itens extraida de d.class

A tela inicial Java usa o estilo de lista `1`, com `W=5` entradas
visiveis, espacamento vertical `V=5` e origem centrada em `(120,160)`.
A versao 59 desenhava as sete a nove opcoes ao mesmo tempo, mesmo que
o MIDlet original mostrasse apenas cinco.

A versao 60 limita o desenho a cinco linhas, centraliza a janela, desloca
o intervalo visivel com o cursor e preserva as acoes reais de `RESUME`,
`START NEW GAME`, `OPTIONS`, `TROPHY`, `STATS`, `HELP`,
`ABOUT` e `EXIT`. O teclado direcional/numerico, `5`, ENTER,
os softkeys e o toque selecionam o mesmo indice global; navegar pelo
menu nao ativa acidentalmente `EXIT`.

O teste `tests/v60_welcome_scroll.lua` percorre as oito opcoes,
verifica a janela e testa selecao por teclado e toque, incluindo a
ultima linha. As capturas reais continuam cobrindo o menu e
as configuracoes no LÖVE.

**Pendente:** a composicao definitiva, o destaque selecionado e a
comparacao visual pixel a pixel com o MIDlet original. Os testes
funcionais aprovados nao equivalem a uma afirmacao de fidelidade 1:1.

## Historico — versao 59

## Versao 59 — medidas extraidas do bytecode

O JAR original (`d.class`, `f(32)`, estilo de lista 1) centraliza
as opcoes em **x=120 / y=160** e calcula a largura pela maior string
mais uma margem de 16 pixels. O port anterior desenhava caixas roxas de
178px para todas as opcoes; a v59 substitui-as por uma lista compacta
com largura medida pela fonte, centralizacao vertical e uma area de
selecao por linha.

A fonte de menu utiliza a primeira face de `1.dat` (20px) quando foi
importada legalmente pelo proprietario. Na ausencia do recurso, usa uma
fonte LÖVE maior e legivel. A arte `menutank.png` e preservada sem
alteracao. Os botões inferiores SELECT e EXIT permanecem funcionais;
teclado, toque, confirmacao de novo jogo e salvamentos foram
regredidos em `tests/v59_welcome_layout.lua` e na suite nativa.

**Limite:** a tipografia/estrutura aproximam o mecanismo original, mas
não substituem uma comparacao pixel a pixel com o MIDlet em execucao.
Nao afirmar que o menu seja uma copia visual exata.

## Histórico — versão 58

## Versao 58 — menu inicial com opcoes do JAR original

O estado 32 de `d.class` usa a string `WELCOME` (indice 156 em `E`).
A funcao Java `f(32)` usa as opcoes localizadas nos indices 1 a 9:
`RESUME` (apenas com save), `START NEW GAME`, `OPTIONS`, `TROPHY`,
`STATS`, `HELP`, `ABOUT`, `MORE GAMES` (apenas se habilitado nessa
edicao) e `EXIT`. A interface Lua agora respeita os nomes e as opcoes
condicionais, com navegacao de teclado, toque e softkeys `SELECT`/`EXIT`.
Ao selecionar `EXIT`, um salvamento com erro impede que a aplicacao feche.

**Limitacao atual:** posicoes, cores e composicao do menu ainda aguardam
conferencia pixel a pixel com a tela Java executada em emulador. A arte da
abertura continua separada do menu; os recursos extraidos do JAR sao locais.
`tests/v58_welcome_menu.lua` e as verificacoes de interface cobrem o fluxo
do menu, mas nao demonstram equivalencia visual integral.

A compilacao automatica para Windows gera um pacote LÖVE portatil. Sem os
recursos privados do JAR, a compilacao publica utiliza apenas os arquivos
ja existentes em `assets/original`.

## Versão 57 — fluxo de abertura confirmado no bytecode

A sequencia **correta** do JAR nao e simplesmente duas imagens consecutivas.
O fluxo observado em `d.class`, `e.class` e na tabela inglesa `E` e:

1. Estado **30**: `oberon.png` durante aproximadamente 3 segundos.
2. Estado **34**: pergunta **DO YOU WANT SOUND?**, com softkeys **YES** e **NO**. A resposta controla o audio do cliente.
3. Estado **31**: `splash.png` durante aproximadamente 3 segundos, apos a escolha de som.
4. Estado **32**: tela principal com titulo **WELCOME** e opcoes do menu.

O estado 33 seleciona idioma quando nao existe uma preferencia armazenada no MIDlet;
essa tela ainda nao foi reconstruida. O layout do menu WELCOME e do prompt de
som ainda precisa ser comparado visualmente com o Java em execucao.

O LÖVE ja implementa o prompt de som entre as duas imagens e respeita a resposta,
sem modificar a partida, nem avancar o tempo do jogo durante a abertura.
`tests/v56_j2me_intro.lua` e `tests/v57_sound_prompt.lua` cobrem o fluxo.
Sem as imagens importadas do JAR, o cliente preserva o acesso ao menu.

## Versão 56 — introducao dos dois PNGs originais

A versao 56 separou `oberon.png` e `splash.png` do menu, mas inicialmente as
exibia em sequencia direta. A etapa 57 corrige a omissao da pergunta sobre som
identificada no bytecode. Nao considerar a sequencia antiga como fiel ao JAR.

## Estado verificado da reconstrução (v55)

- O teste nativo do LÖVE agora gera e valida **31 telas**. O validador lê os nomes diretamente de `core/retro_smoke.lua` e rejeita capturas ausentes ou PNGs corrompidos; não compara ainda as telas pixel a pixel com o MIDlet Java.
- `scripts/import_j2me_assets.py` reconhece os **19 PNGs do JAR Fish_Tycoon_240x320-111845-mobiles24.jar**, incluindo `isola.png`, `oberon.png`, `people.png`, `supllies_big.png` (grafia original) e `supply_animations.png`. A extração foi verificada localmente contra o JAR, com igualdade byte a byte.
- O GitHub Actions executa testes Lua, importação/validação PNG e renderização real do LÖVE. No Windows, `TESTAR_LUA.bat` percorre todas as suítes Lua existentes.
- **Não está concluído 1:1**: layouts de menus e várias regras provisórias continuam sem comparação integral com o Java em execução. Não confundir testes de funcionamento com fidelidade histórica comprovada.

Para importar todas as imagens do seu JAR sem modificar o arquivo de origem: `python scripts/import_j2me_assets.py Fish_Tycoon_240x320-111845-mobiles24.jar`.

## Histórico de versões

### Versão 38 — estados de loja e pesquisa

Desde a v19, **a interface padrão é `ui/retro.lua`**, desenhada em 240 × 320 e ampliada sem perder proporção. A tela anterior (`ui/view.lua`) foi preservada para regressão, mas não é mais o menu principal. O motor Lua, sprites e estrutura de saves permanecem.

## Novo na v38 — compras e pesquisas sem comandos impossiveis

- A loja exibe **OWN** para equipamentos/tanque adicional ja adquiridos, **FULL** quando nao cabem mais ovos e **NO $** quando falta dinheiro. Esses botoes ficam desativados antes do toque, usando os mesmos limites de `Game:purchase`.
- Consumiveis mostram as doses/porcoes existentes ao lado do preco; nenhuma compra automatica ocorre ao selecionar um item.
- Pesquisas mostram dinheiro atual, custo da proxima melhoria e duracao em minutos segundo `core/config.lua`; os controles START ficam indisponiveis durante outra pesquisa, no ultimo nivel e quando falta dinheiro.
- Incluidas verificacoes em `tests/v38_shop_research_states.lua` e duas capturas nativas extras no CI. **Os custos e tempos sao provisoes do port Lua, nao valores autenticados do JAR J2ME.**
- Somente interface: o motor, os saldos, os recursos graficos e os salvamentos nao foram alterados. A disposicao ainda nao foi confirmada 1:1 com o menu Java.

## Novo na v37 — arte do TROPHY recuperada do JAR

- A tela de trofeus deixa de ser uma lista de texto: sete posicoes mostram
  a esfera azul de `trhopy_ball.png` quando extraida do **JAR do usuario**.
  A disposicao em duas fileiras (4+3) e uma adaptacao nao validada 1:1.
- Os peixes magicos ja descobertos aparecem sobre suas esferas usando os
  mesmos sprites de corpo/barbatana da partida, e os nao descobertos
  permanecem ocultos. Tocar em uma esfera exibe o nome correspondente.
- O importador `scripts/import_j2me_assets.py` agora extrai tambem o arquivo
  grafico `trhopy_ball.png`. Ele nao e versionado no repositorio publico.
- O runner de testes continua funcional sem esse arquivo: os trofeus usam
  um desenho de reserva, sem perder navegacao ou progresso.
- Incluidos `tests/v37_trophy.lua` e captura adicional do menu TROPHY.
  Biologia, mercado, audio, salvamento e demais menus nao foram alterados.

## Novo na v36 — moldura sem sobreposicao de barbatanas

- **Selecao de sprite:** o interior da moldura amarela J2ME e de 54×35 pixels. Peixes com barbatanas de ate 39 pixels eram desenhados sobre a borda e podiam invadir o painel superior; agora apenas o desenho selecionado respeita esse recorte, sem redimensionar os recursos originais.
- **Compositor:** o fundo da regiao selecionada e restaurado usando exatamente a mesma area, removendo diferencas de 1px nas extremidades. O resto do aquario continua com o movimento natural, sem deslocar peixes.
- **Coordenadas:** a janela utiliza uma funcao unica de conversao de pixels logicos 240×320 para o recorte nativo do LÖVE, incluindo escala fracionaria e restauracao de recortes anteriores.
- **Regressao:** nova suite `tests/v36_selection_scissor.lua`; 24 capturas reais, agora com exemplar de barbatana alta. Motor, genetica, economia, arquivos de imagem e formato dos salvamentos intactos.
- A comparacao 1:1 com o MIDlet Java em execucao ainda nao esta concluida.

## Novo na v35 — moldura superior e comparacao na sala correta

- **Painel de selecao 240x320:** a moldura superior agora ocupa x=12..227, y=0..33, com interior arroxeado e linhas claras de relevo inspiradas na captura Java enviada. A versao anterior iniciava em y=1 e ultrapassava a base do painel.
- **Comparacao honesta:** a fixture Greenfin Fruitfish/idade 21 do teste nativo agora tambem e capturada no **SALE TANK**, usando 
`tank3.png` e os letreiros For Sale! do mesmo aquario mostrado na referencia do usuario. Isso elimina uma comparacao enganosa com o fundo 
`tank1.png` do aquario principal. Os outros peixes sao apenas uma fixture de teste, sem tentativa de replicar trajetorias exatas do Midlet.
- **Regressao:** adicionado 
`tests/v35_selection_panel.lua`; capturas reais sobem de 22 para 23 e o GitHub Actions acompanha a nova fixture.
- Nenhuma regra de jogo, recurso original, musica ou formato de salvamento foi alterado. Fidelidade 1:1 total continua pendente de capturas adicionais do MIDlet.

## Novo na v34 — selecao sem alterar o nado dos demais peixes

- A tela de detalhes **nao desloca mais artificialmente** os peixes que cruzam a moldura do selecionado. Todos conservam suas coordenadas de movimento independente; a area da moldura e restaurada com o fundo azul do proprio `tanktop.png` antes de desenhar o selecionado por ultimo. A limpeza da imagem usa recorte de tela compativel com viewport fracionario.
- Se o peixe selecionado morrer ou for movido para outro aquario durante a visualizacao, a selecao e encerrada sem manter um ID invalido.
- O smoke test agora posiciona um **GREENFIN FRUITFISH**, idade 21, na captura `03-peixe.png` para permitir comparacao visual com a imagem Java recebida. E uma fixture isolada e nunca altera a partida do usuario.
- Novo `tests/v34_detail_overlay.lua` e ajustes de regressao na selecao; nenhuma modificacao em biologia, genetica, economia, sprites, audio ou formato de saves. A equivalencia de todos os quadros do MIDlet ainda nao foi provada.

## Novo na v33 — isolador visível e seleção com moldura superior

- **Dois peixes no recipiente:** os centros foram corrigidos para x=96 e x=144 no recipiente de 98px; a largura e a altura são ajustadas somente nesse compartimento para manter o sprite entre x=70..168 e y=274..298, sem ficar atrás dos botões inferiores.
- **Peixe selecionado no isolamento:** usa a moldura amarela e a âncora (91,53), como as demais telas de seleção. Os outros exemplares continuam visíveis no recipiente inferior.
- **Aquários sem redução artificial:** sprites dos tanques continuam com 21/35/50px nativos da v32. A redução na bandeja é uma adaptação visual de layout, ainda não confirmada contra a exibição do MIDlet Java.
- **Validação:** nova suíte `tests/v33_isolation_layout.lua` verifica todas as 441 combinações adultas no isolador, áreas de toque, teclas inferiores, desenho sem mutar o jogo e navegação. O GitHub Actions passa a capturar 22 telas, com duas novas telas do isolamento.
- **Sem alteração de simulação:** salvamentos v9, genética, pesquisas, preços e PNGs originais não foram modificados.

## Novo na v32 — sprites 1:1 por idade

- O bytecode da classe `m` do Fish Tycoon Java fornece os tamanhos de sprite
  **21 × 8 px (idade 0–5)**, **35 px de largura (idade 6–19)** e
  **50 px de largura (idade 20+)**; alturas das formas vêm das tabelas em `j`.
- A tela `ui/retro.lua` deixou de reduzir os sprites originais para 85%.
  A composição de aquário agora usa escala 1, independentemente da idade.
- Os limites e as áreas de toque usam a largura e a altura real dos sprites,
  incluindo a barbatana adulta. O peixe selecionado mantém a âncora do J2ME
  (91,53), sem modificar os dados nem o nado livre da v31.
- Adicionado `ui/fish_geometry.lua` e `tests/v32_fish_sizes.lua`, com cobertura
  das 441 combinações de adultos e das três faixas de crescimento.
- Nenhuma modificação em salvamento, biologia, genética, dinheiro ou imagens.
  O Android e a inspeção quadro a quadro do MIDlet continuam pendentes.

## Novo na v31 — nado independente baseado no JAR

- **Distribuição livre**: os peixes deixam de ocupar quatro colunas fixas. Posição inicial e direção passam a ser derivadas do identificador individual, com trajetórias independentes em todo o aquário.
- **Velocidade e direção**: o novo renderizador `ui/j2me_motion.lua` usa a representação de movimento 16.16 identificada em `m.n()`/`h.c()` no Java. A conversão para segundos (60 atualizações/segundo) e a semente visual por ID são adaptações documentadas, **não equivalência 1:1 comprovada**.
- **Sem alterar a partida**: a nova trajetória é apenas de apresentação. Não usa o gerador aleatório da simulação, não introduz campos no salvamento e não altera o antigo `ui/swim.lua` usado pelos testes da interface moderna.
- **Seleção preservada**: ao selecionar um peixe, sua moldura permanece na posição J2ME conhecida e outros peixes não devem invadi-la. `tests/v31_motion.lua` testa limites, deslocamento, direção, independência da ordem, salvamento e interação.

## Novo na v30 — seleção do peixe conforme a captura J2ME

- **Foco do peixe:** na tela de detalhes, o peixe selecionado é desenhado na região superior central, com o retângulo amarelo de 56 × 37 pixels cuja posição foi medida na captura J2ME fornecida (x=63, y=34). Antes, o destaque acompanhava a trajetória aleatória do peixe e aparecia frequentemente longe da referência.
- **Camadas:** o peixe selecionado é renderizado depois dos demais para evitar que seu corpo e o marcador amarelo sejam encobertos. Os outros peixes continuam nadando, mas sem alterar o estado da simulação.
- **Voltar e navegar:** SELECT/BACK e 2/4/6/8 continuam permitindo explorar os peixes; ao sair da seleção o peixe volta à posição normal de nado. O toque na tela do aquário mantém o alvo proporcional ao sprite.
- **Testes:** `tests/v30_selection.lua` valida posição do contorno, ordem de desenho, troca de exemplar e ausência de mutação do save. `core/retro_smoke.lua` acrescenta uma captura nativa dedicada à seleção de outro peixe. Nenhuma regra de pesquisa, genética ou economia foi alterada.

## Novo na v29 — ícones J2ME e retorno correto de menus

- Ações, transferências e tratamentos usam miniaturas do **atlas já recuperado do JAR** (ícones de comida, medicamentos, dinheiro, peixes e tanques), com texto reserva quando esses recursos ainda não foram importados. Os botões continuam compactos em 240 × 320 e os produtos continuam com as regras da v28.
- **Navegação corrigida:** loja e pesquisa abertas pela barra superior agora voltam ao aquário ou menu de origem (tecla F2/BACK ou Esc); anteriormente voltavam sempre ao menu de pausa, prejudicando a continuidade da partida. Alternar diretamente entre loja e pesquisa mantém o destino de retorno.
- Os ícones são exclusivamente visuais e não fazem nenhuma compra ou transferência. Os produtos do JAR são de estudo local e não são redistribuídos pelo repositório público.
- Os testes `tests/v29_navigation_icons.lua` conferem imagens originais, fallback, toque, retorno e estados de compra/transferência, sem modificar genética ou salvamentos. Ainda não representa confirmação pixel a pixel de todos os menus do Java original.

## Novo na v28 — menus de ações, transferências e tratamentos

- **Ações do peixe** organizadas numa lista compacta 240×320, com identificação, idade, saúde e preço. Vender diretamente e alterar preço só ficam disponíveis para **adultos no tanque de vendas**, em respeito às regras já implementadas pelo motor.
- **Transferências** mostram ocupação/capacidade e bloqueiam visualmente destino atual, tanque fechado, tanque cheio, venda de juvenis e saída do isolamento durante gestação. O motor continua sendo a autoridade para todas as transferências.
- **Tratamentos** exibem a doença e estoque disponível. Medicamentos inadequados, sem estoque ou hormônios para peixes acima de 40 ficam inativos; os demais aplicam as mesmas regras da v27.
- O retorno **BACK/F2** permanece funcional e as 3 telas foram incluídas no teste do LÖVE nativo (18 capturas ao todo). Nenhum recurso original, simulação ou formato de salvamento foi alterado.
- **Fidelidade:** essa organização é uma correção de usabilidade alinhada à resolução original, mas **a disposição exata do JAR ainda precisa de capturas dessas telas para verificação 1:1**.

## Novo na v27 — menu e navegação derivados do JAR

- O menu de pausa agora usa a nomenclatura confirmada pela tabela inglesa do próprio JAR: **RESUME, START NEW GAME, OPTIONS, TROPHY, STATS, HELP, ABOUT** e **SAVE & EXIT**. A disposição gráfica compacta ainda precisa ser comparada pixel a pixel com uma captura desse menu Java.
- **TROPHY** abre a coleção das sete espécies mágicas; **STATS** mostra peixes vivos, nascimentos, vendas, descobertas, mortes e balanço; **HELP** mostra os controles já implementados no port Lua. As duas páginas novas são funcionais, mas seu layout ainda não é apresentado como nativo comprovado.
- **START NEW GAME** dentro do jogo usa confirmação e o arquivamento de salvamentos já existente. **CANCEL** retorna ao menu de origem, evitando jogar o usuário no menu errado.
- Suprimentos e pesquisas continuam disponíveis na barra superior dos aquários e nos seus respectivos botões; o teste nativo cobre a navegação atualizada.
- O motor e o formato de salvamento permanecem inalterados. A lógica **SAVE & EXIT** salva e retorna ao menu inicial da versão Lua (não fecha a aplicação), deixando **RESUME** acessível.

## Novo na v26 — placas de venda nativas e menu sem marca provisoria

- **Tanque de vendas fiel ao JAR:** duas placas de madeira com `For Sale!` ja fazem parte do proprio `tank3.png`, nas laterais do cascalho. Removidas as etiquetas desenhadas em cada peixe que duplicavam as placas e se moviam de forma errada. A selecao e os precos dos peixes continuam funcionando.
- **Menu inicial sem splash:** corrigido texto de reserva para **FISH TYCOON / MOBILE**, sem o sufixo inventado `- LUA`; quando `splash.png` foi importado do JAR, o arquivo original continua sendo mostrado integralmente.
- **Teste nativo ampliado:** captura adicional do tanque de vendas e de um peixe selecionado nesse tanque, totalizando 11 imagens verificadas pelo LÖVE real no GitHub Actions.
- **Regressao:** atualizado o teste v25 para nao exigir sobreposicao duplicada, adicionado `tests/v26_sale_art.lua` cobrindo desenho do fundo e ausencia do rotulo flutuante. Sem mudancas no motor Lua ou nos salvamentos.

## Novo na v25 — controles 1:1 da barra e selecao

- Barra de 11 comandos com limites inteiros, usando tres miniaturas de tanques com 18px cada e oito controles restantes de 23 a 24px. Os botões não deixam frestas e mantêm o atlas original quando importado.
- A área de seleção acompanha o tamanho efetivo do peixe (adulto, jovem ou alevino), evitando selecionar um filhote ao tocar longe do seu sprite.
- A etiqueta **For Sale!** continua visível sobre adultos no tanque de vendas mesmo na tela de detalhes, como na captura J2ME fornecida.
- Teclas **F1/F2** acionam respectivamente os comandos inferiores à esquerda/direita, em complemento ao mouse e às teclas de celular **2/4/5/6/8**. O comando só é executado se estiver visível e habilitado.
- `tests/v25_controls.lua` cobre os limites da barra, dimensões dos alvos, etiquetas e botões inferiores. Não modifica genética, economia, fontes ou salvamentos. O trabalho 1:1 completo exige conferir outras telas do MIDlet.

## Novo na v24 — dimensões e seleção 240×320

- **Escala real:** a janela usa toda a largura/altura cabível, inclusive em tamanhos não múltiplos de 240×320 (por exemplo, 468×858). O filtro de texturas continua nearest; o motor biológico e o salvamento não mudaram.
- **Corpos inteiros:** posições visuais dos peixes são limitadas pela metade da largura de cada faixa etária, evitando peixes adultos cortados nas bordas da água.
- **Seleção:** peixes adultos selecionados recuperam o corpo de 50 pixels do atlas do JAR; o destaque amarelo e os alvos de toque acompanham a posição efetivamente desenhada.
- **Painel de saúde:** a barra normal usa verde, como na captura J2ME; quando a saúde cai abaixo de 35 a barra fica avermelhada.
- **Testes:** `tests/v24_viewport.lua` verifica a área lógica, escala em tamanhos fracionários, alvo de seleção, ordem de desenho, bordas e preservação dos dados do jogo. **Não equivale a uma comparação pixel a pixel com o JAR.**

## Novo na v23 — tipografia bitmap original

- As três fontes de `1.dat` (104 glifos cada) são extraídas **localmente** pelo script `scripts/import_j2me_fonts.py` sem copiar fontes comerciais para o GitHub. O `.love` de teste local inclui os dados recuperados do JAR fornecido pelo usuário.
- `ui/bitmap_font.lua` usa as posições exatas por glifo da classe `i` do Java, respeitando largura variável, alinhamento central/direita e corte de textos longos.
- Os menus 240×320 usam fonte bitmap quando presente; o CI público usa a fonte LÖVE reserva, porque não inclui o JAR comercial.
- Nenhuma alteração na lógica do jogo ou na estrutura dos salvamentos.

**Para usar seu JAR em uma cópia do código:** `python scripts/import_j2me_fonts.py Fish_Tycoon.jar`. Então inicie com LÖVE normalmente. As fontes são de uso privado para estudo.


## Novidades da v22 — teclado J2ME e interface compacta

- **Navegação por teclado:** teclas **2/4/6/8** ou setas movimentam o foco nos menus e **5/Enter/Espaço** ativam a opção. Um contorno amarelo indica qual botão está selecionado. `Esc` continua retornando. Na seleção de peixes, as teclas 4/6 ainda percorrem os exemplares.
- **Novo jogo e opções:** menus acessíveis sem mouse; com um salvamento existente, CONTINUE é o padrão, e sem save o foco inicia em NEW GAME. Comprar um item ainda exige focar o botão **BUY**, sem compra acidental ao destacar uma linha da loja.
- **Barra superior:** os 11 slots ocupam toda a largura do J2ME, e o valor do dinheiro não cobre o último ícone. Corrigidos os recortes de alimentação e tratamentos do atlas `assets.png` opcional; a quantia permanece visível na loja.
- **Menus:** loja, pesquisas e comandos usam como base `menutank.png`, recurso do JAR que já estava no pacote, em vez de desenhar os corais do aquário principal atrás de todos os diálogos.
- **Testes:** 8 novos cenários em `tests/v22_keypad.lua`. O teste anterior do atalho alimentar foi ajustado para as novas posições da barra. Não houve mudança no motor nem no formato dos saves.
- **Limite da fidelidade:** ainda faltam mapear corretamente as **fontes bitmap** e comprovar a geometria dos menus com capturas diretas do MIDlet. Não confundir testes de renderização com verificação pixel a pixel do J2ME.

## Novidades da v21 — loja e pesquisas no layout compacto

- **Loja de suprimentos:** até quatro produtos por página com miniaturas reais do `store.png` do JAR, seleção de um produto separada do botão **BUY**, preço sempre visível, descrição contextual, navegação por páginas e botão **BACK**. Em cópias sem esse PNG, mantém um quadro de reserva, sem impedir compras.
- **Pesquisas:** painéis compactos de três áreas com nível atual, barra de progresso, efeito atual, botão **START/MAX** e estado da pesquisa ativa. O motor de estudos e os valores continuam os da v20; **não** foram inventados novos custos ou tempos do JAR.
- **Validação:** nova suíte `tests/v21_shop_research.lua` com oito verificações, incluindo compra, paginação, seleção, limite de pesquisas, compatibilidade com fallback e retorno ao menu. Total: 34 arquivos de testes Lua executados sem falha.
- **Capturas nativas:** smoke do LÖVE agora cobre nove telas, acrescentando outra página da loja e a pesquisas. A execução real é comprovada apenas depois da aprovação do GitHub Actions, não pelos testes com mocks.
- **Continuidade:** nenhuma alteração no motor de peixes, recursos comerciais existentes, formato de saves ou progresso de usuários. O projeto continua **parcialmente aproximado** ao Java: a correspondência pixel a pixel de menus e os nomes/preços de produtos não foram comprovados com screenshots do MIDlet.

## Novidades da v20 — referência visual J2ME

- Barra superior: miniaturas dos três tanques e ícones recortados diretamente de `assets.png` (peixe, alimentação, medicamentos, reprodução, loja, pesquisa, dinheiro). O atlas permanece **opcional no GitHub público**; importe o JAR para obter os ícones originais. Sem ele, os comandos continuam funcionando com símbolos de reserva.
- A seleção usa os 21 nomes de corpo e 21 nomes de barbatana recuperados dos textos ingleses do JAR (exemplo: **GREENFIN FRUITFISH**), mantendo os índices genéticos intactos.
- Isolamento: corrigida a sobreposição — os peixes agora são renderizados **sobre** o recipiente azul.
- Tanque de vendas: indicação **For Sale!** junto aos adultos.
- Controles: `F` ou espaço para escolher peixe, `4/6` e `2/8` ou setas para navegar, `5` para abrir ações, `Esc` para voltar. Mouse e toque funcionam normalmente. O botão de alimento na barra executa alimentação e a pesquisa/loja abrem pelas novas miniaturas.
- Não há mudanças nos salvamentos nem nas regras de crescimento e genética. Ainda não há correspondência pixel a pixel certificada com todas as telas J2ME; para capturar diferenças, consulte `docs/FASE_20.md`.

## Jogar

Abra `Aquario-de-Isola-v32.love` usando [LÖVE 2D 11.4](https://love2d.org/) ou execute `love .` no diretório. Inicialmente aparece um menu com **CONTINUE, NEW GAME, OPTIONS, ABOUT**. Para criar uma partida nova, clique em **NEW GAME**. Se já existir jogo salvo, há confirmação antes de substituí-lo; o save antigo é arquivado em `fish_tank_save_before_new_game.json` e permanece recuperável. Uma falha ao criar arquivo arquivado bloqueia a substituição.

No aquário, toque em um peixe para abrir a seleção (informações e comandos **SELECT/BACK**). Na parte inferior, **FISH** seleciona um peixe e **MENU** abre o menu do jogo. A barra superior seleciona tanques e abre loja, pesquisa e coleção. O recipiente azul inferior dá acesso ao isolamento. Dentro do menu, os comandos **MOVE**, **FEED**, **TREAT**, compra de suprimentos, venda e pesquisa seguem ativos, usando o mesmo motor da v18.

**Configurações**: música, velocidade e intervalo de crescimento. Não há necessidade de editar arquivos para jogar de novo. A simulação fica pausada no menu inicial e nas configurações; continua durante a partida.

## Fidelidade e recursos do JAR

Foram adotadas as proporções 240 × 320, a composição `tanktop.png` + `tank1/2/3.png`, o recipiente `isolation_tank.png`, a barra superior compacta e a estrutura da tela de seleção da imagem de referência do jogo original. O pacote local `.love` inclui também `splash.png`, `assets.png` e `gameMenuTank.png`, extraídos do JAR de referência.

Por direitos de redistribuição, os **três PNGs adicionais não foram publicados no GitHub público**. Para completar visualmente uma instalação criada apenas a partir do repositório, utilize o JAR que você possui e execute:

```sh
python3 scripts/import_j2me_assets.py /caminho/para/Fish_Tycoon_240x320.jar
```

Sem os três PNGs, o jogo continua jogável, com título desenhado pelo código e fundos já existentes. O `.love` de teste disponibilizado na conversa contém a arte do JAR. O `README` separa o que já se aproxima visualmente do original do que ainda exige investigação: fontes gráficas exatas, layout de todos os menus, nomes reais e telas não fornecidas nas referências.

## Testes

```sh
texlua tests/v19_retro.lua
texlua tests/v20_visual_controls.lua
texlua tests/v21_shop_research.lua
texlua tests/v22_keypad.lua
texlua tests/v24_viewport.lua
texlua tests/v25_controls.lua
texlua tests/v26_sale_art.lua
texlua tests/v27_menu.lua
texlua tests/v28_actions.lua
# regressão completa
for file in tests/*.lua; do texlua "$file"; done
```

GitHub Actions contém dois testes nativos no LÖVE/Xvfb: o anterior para a interface legada e o novo `FISH_RETRO_SMOKE=1`, que captura onze telas J2ME em 480 × 640. **Isso valida renderização e navegação, não comprova correspondência pixel a pixel com todo o jogo Java.**

A base canônica é a branch `main` de https://github.com/SrTristeSad/Fish-Tycoon-Lua. Toda alteração deve ter commit. Consulte também `AGENTS.md` e `RECURSOS_E_DIREITOS.md`.

Consulte [`docs/FASE_26.md`](docs/FASE_26.md) e [`docs/FASE_22.md`](docs/FASE_22.md) e [`docs/FASE_21.md`](docs/FASE_21.md) para os detalhes de construção e o que permanece diferente do JAR.

