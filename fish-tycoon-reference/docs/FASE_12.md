# Fase 12 — recuperação de salvamentos e relatório de progresso offline

## Continuidade

Esta versão modifica diretamente a base da v11: não substitui o motor de criação, a simulação cronológica, os 21 corpos e 21 barbatanas, os sprites ou as músicas. O formato persistido continua `version = 9`, a identidade LÖVE continua `mar_de_isola_lua`, e os arquivos permanecem `fish_tank_save.json` e `fish_tank_save.backup.json`.

## Correção: JSON válido pode conter estado inválido

Um JSON parseável pode conter, por exemplo, idade de peixe como string, ID duplicado, nível de pesquisa incorreto ou `stats.sold = "zero"`. A v11 aceitava algumas estruturas desse tipo, e o erro surgia somente ao simular ou mostrar a interface. Outras provocavam exceções dentro de `Game.fromTable` durante o carregamento, impedindo o uso do backup.

A v12 adiciona `validateSave` ao fim da migração. São verificados valores finitos, IDs únicos, forma/barbatana, idade, saúde, alimento, dinheiro, estoque, cotações, pesquisas, ovos, estatísticas, eventos e estruturas auxiliares. `Storage.decodeGame` protege a chamada ao construtor com `pcall` para que qualquer falha de migração seja tratada como arquivo inválido e permita tentar o backup. Apenas a validação foi ampliada; o layout serializado de saves válidos não mudou.

Isso é **recuperação por backup**, não conserto automático de qualquer save. Se o principal e o backup forem inválidos, o jogo informa a falha; uma perda de dados ainda é possível.

## Relatório de sessão offline

Novo módulo `core/offline_report.lua`. O resumo é criado comparando contadores antes e depois de `Game:offline`; mostra tempo simulado, variação do dinheiro, total de peixes, nascimentos, vendas, mortes, curas, doenças, visitas ao mercado, descobertas e progressão de pesquisa. Não cria sorteios, não altera estado do motor e não infere eventos a partir de mensagens vagas.

O relatório abre automaticamente quando o retorno ao jogo processa **pelo menos 60 segundos** de tempo offline e pode ser reaberto pelo botão `Resumo offline` no tanque principal ou secundário sem um peixe selecionado. Sessões com menos de um minuto não abrem diálogo. O limite já existente de 24 horas para o tempo offline continua vigente. O relatório é temporário (não acrescenta campos ao save) e contabiliza **variações líquidas**: por exemplo, um peixe que nasceu e morreu aparece nos dois contadores, mas pode não mudar o total de peixes.

## Testes

- `tests/v12_save_safety.lua`: sete testes de carregamento normal e recuperação quando há idade inválida, estatísticas incorretas, pesquisa inconsistente, dados auxiliares inválidos, ID duplicado ou ovo malformado.
- `tests/v12_offline.lua`: quatro testes de resumo, ausência de alterações, visitas offline e diálogo/UI.
- Todas as suítes anteriores foram executadas sem falhas no `texlua`.

## Limitações

A janela real do LÖVE ainda não foi executada e inspecionada visualmente; a interface é verificada por mocks. A matemática original do JAR para níveis de pesquisa e outros sistemas continua parcialmente aproximada. Os assets extraídos do jogo comercial são apenas para estudo local, sem licença de redistribuição pública.
