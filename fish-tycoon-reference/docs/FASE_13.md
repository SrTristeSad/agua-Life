# Fase 13 — integridade do save e navegação de relatórios

## Escopo

Implementada sobre a v12; não recria o motor, não altera regras genéticas ou econômicas nem redistribui formatos adicionais. Mantém o save `version=9` e a identidade `mar_de_isola_lua`.

## Escrita e recuperação

`Storage.save` continua preservando o arquivo anterior que seja válido em `fish_tank_save.backup.json`. Na v13, uma falha ou truncamento do backup interrompe o salvamento antes de alterar o arquivo principal. Após gravar o principal, os bytes são lidos novamente; uma diferença produz erro, mantendo o backup válido. Se a gravação falhar, a âncora do relógio do objeto em memória é restaurada. Em um dispositivo real, verificar os bytes não equivale a garantir sincronização física da unidade de armazenamento; não é uma transação atômica.

`validateSave` agora verifica também que `next_id` excede todos os IDs dos peixes presentes, que o estado da loja é booleano, que o parceiro de gestação possui índices válidos, que os ovos não têm instante negativo, que a pesquisa ativa é booleana/tabela válida e que todos os contadores básicos são números inteiros não negativos. Contadores adicionados tardiamente têm padrão zero quando ausentes em saves anteriores.

## Relógio

Se `now <= wall`, `Game:offline` retorna zero e não modifica `wall`. Quando o relógio volta ao normal, continua usando a âncora original. Progressão offline continua limitada a 24h, sem multiplicar pela velocidade escolhida com o jogo aberto.

## Interface

O relatório offline, que antes mostrava somente oito entradas, apresenta sete por página e botões anterior/próxima quando necessário. A interação dentro do diálogo continua bloqueando as telas de fundo.

## Verificações

- `tests/v13_integrity.lua`: dez testes cobrindo parâmetros inválidos, salvamento antigo com contadores ausentes, interrupção simulada do backup e do principal, relógio retrocedendo e navegação do relatório.
- Todas as 25 suítes disponíveis em `tests/*.lua` passaram com um interpretador Lua 5.4 local. A sintaxe e o funcionamento da simulação foram validados; a execução em janela real de LÖVE **não** foi validada neste ambiente.

## Limitações

Os gráficos e áudios comerciais extraídos do JAR são destinados a testes locais. O código Java não foi novamente descompilado nesta etapa; regras do J2ME que continuam aproximadas permanecem assim. A gravação verificada não substitui mecanismos transacionais oferecidos pelo sistema operacional nem é uma garantia contra falhas físicas.
