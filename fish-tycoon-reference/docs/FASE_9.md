# Fase 9 — histórico de compradores, correção econômica e salvamento de segurança

## Base e escopo

Continuação da pasta `FishTycoonLua_v8` sem retirar recursos ou recriar o motor. O arquivo `.love` continua usando identidade de armazenamento `mar_de_isola_lua`; `core/game.lua` migra versões 2 a 8 para o esquema 9. Os PNG/OGG e dados genéticos recuperados do JAR foram preservados.

## Instrumentação do mercado

- A partir de `core/market.lua`, `Market.step()` registra `sold` (compra), `passed` (visitou ofertas adultas mas não comprou) ou `empty` (nenhuma oferta adulta). Cada registro armazena identificador da visita, segundo simulado e, quando há venda, ID, corpo, barbatana, preço pedido, cotação e preço efetivamente recebido.
- A lista `state.market.history` mantém no máximo 12 registros; `last_visit` aponta o resultado mais recente. O painel de histórico mostra os últimos sete. A venda **manual** altera `last_sale`, mas não inventa a presença de um cliente nem conta como visita.
- A rotina de avaliação de demanda JAR reconstruída não foi alterada: patamares de procura `30/10/4/1`, limite de uma compra por visita e passagem do tempo independente do crescimento. O cronômetro de uma visita a cada 5 segundos simulados continua uma **aproximação do port**.
- `View:update()` detecta crescimento da estatística de vendas e exibe um aviso visual durante 2,5 segundos na área de vendas. É um indicador do port, não uma animação extraída do JAR.

## Bônus de riqueza

Antes, `Game:sell()` removia o peixe do tanque e somente depois procurava o peixe mágico que habilita o bônus. Isso impedia que a venda do último peixe mágico recebesse o benefício. Agora o estado é consultado antes da remoção. O multiplicador Lua de 15% foi preservado sem atribuí-lo ao bytecode original. O cálculo usa `floor(price * 115 / 100)` para evitar `floor(200*1.15) = 229` em plataformas de ponto flutuante.

## Integridade dos saves

- O gravador usa `love.filesystem`. Antes de salvar, lê o arquivo anterior e valida o esquema; apenas então o copia para `fish_tank_save.backup.json`.
- Se a escrita do backup falhar, não sobrescreve o principal. Se o principal for corrompido, o carregador tenta validar e usar o backup.
- A cópia anterior NÃO é backup atômico nem protege contra corrupção simultânea dos dois arquivos ou falhas do disco. Para minimizar perda adicional, o backup não é substituído quando o arquivo principal anterior está inválido.
- O arquivo principal continua com o nome `fish_tank_save.json`. O jogo exibe aviso na interface quando recupera o backup.

## Testes específicos

`tests/v9_regression.lua`: 12 casos, incluindo cap de histórico, venda automática, serialização/migração, bônus do último peixe mágico e determinismo por partição do tempo.

`tests/v9_storage.lua`: 8 casos, com filesystem falso para corrupção de JSON, falhas de escrita e recuperação de salvamentos antigos.

`tests/v9_ui_smoke.lua`: navegação no painel, histórico vazio, recusa, venda, aviso visual e bloqueio de cliques fora do modal.

Os testes anteriores foram preservados, atualizando apenas as verificações do número do esquema corrente de 8 para 9. Foram repetidos testes de mercado, genética, incubação, UI, recursos e performance.

## Limitadores

Abertura em uma janela real do LÖVE, entrada física por toque e port Android ainda não foram testados. A modelagem dos clientes, estados originais de venda e pesquisas segue incompleta frente ao JAR.
