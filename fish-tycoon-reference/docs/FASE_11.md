# Fase 11 — cronologia do motor e transparência das pesquisas

## Objetivo e escopo

Continuação direta de `FishTycoonLua_v10`, sem alterar o esquema de salvamento (`version=9`), nome do arquivo (`fish_tank_save.json`) ou identidade LÖVE (`mar_de_isola_lua`). Assets, motor genético e demais módulos permanecem da versão anterior.

## Correção da linha do tempo

Na versão 10, `Game:advance(600)` processava todas as visitas da loja de um intervalo ANTES de envelhecer os peixes; já `advance(300); advance(300)` podia intercalar a atuação dos sistemas de forma diferente. Também era possível completar uma pesquisa em 240 segundos e só aplicar o novo nível *depois* do crescimento de 600 segundos.

Na versão 11, `Game:advance` separa o intervalo solicitado nos limites cronológicos relevantes:

1. próxima visita do comprador (enquanto a loja estiver aberta);
2. próximo ciclo de envelhecimento;
3. data de conclusão da pesquisa ativa;
4. data de eclosão de ovos comprados.

Em cada limite, atualiza-se o tempo; concluem-se eventos com prazo; processa-se a loja na posição cronológica correta; e realiza-se o envelhecimento ao chegar ao limite. A eclosão da gestação dos peixes continua dependente da idade, como na versão 10. O algoritmo não cria campos persistentes nem usa sorteios extras.

A lógica de mercado e as probabilidades de pesquisa continuam parcialmente **aproximadas**: esta mudança corrige a execução no tempo, e não transforma hipóteses em regras provadas do JAR.

## Projeção de pesquisa

`core/research_preview.lua` usa `Care.foodDrainChance`, `Care.environmentDelta` e `Market.traffic` para calcular o benefício atual e projetado das pesquisas. O painel exibe uma linha adicional com os números do próximo nível. Ambiente apresenta o **delta biológico médio de saúde** entre as 441 combinações; não inclui efeitos de doença, fome ou equipamentos. Publicidade apresenta o **índice de público do port**, não um número comprovado de visitantes do JAR.

## Testes

- `tests/v11_timeline.lua`: verifica horários de visita, pesquisa ativa antes do crescimento, elegibilidade após amadurecimento, equivalência entre avanço único e parcelado, eclosão exata, roundtrip do save e loja fechada.
- `tests/v11_research.lua`: testa projeções para níveis 0–3 e ausência de dados em pesquisa desconhecida.
- `tests/v11_ui_smoke.lua`: interface de pesquisas renderiza valores reais calculados, inclusive nível máximo e barra de tempo restante.
- 19 suítes preexistentes executadas sem regressões; `tests/v8_performance.lua` manteve desempenho de 24h simuladas em aproximadamente 0,15 s nesta execução de terminal, sujeito à máquina e cenário do teste.

## Limitações

Não houve validação da aplicação numa janela gráfica real do LÖVE nem no Android. Os testes de interface usam mocks. A projeção de pesquisa reflete regras do port Lua; custos, duração e alguns efeitos ainda não foram recuperados integralmente do JAR. Assets originais são apenas para estudo local e podem ter restrições de redistribuição.
