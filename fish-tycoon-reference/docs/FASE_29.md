# Fase 29 — ícones J2ME nos menus e retorno contextual

A reconstrução do jogo mantém a resolução original de 240×320. A interface da v28 oferecia tratamento e transferência somente em linhas genéricas. A v29 utiliza **apenas miniaturas existentes nos atlas** importados do JAR, incluindo produtos em `store.png`, miniaturas de tanque e ícones em `assets.png`. Sem os recursos comerciais, há um fallback de texto que mantém os comandos utilizáveis. Nenhum arquivo gráfico foi adicionado, editado ou removido.

As telas de ações, tratamentos e movimentos continuam apresentando disponibilidade, estado e estoque. `Retro:iconRow()` usa a mesma geometria e hitbox dos botões anteriores, mas separa à esquerda uma área de 21px para o sprite. No menu de transferências, `Retro:roomIcon()` utiliza as miniaturas já existentes dos três tanques e a arte de isolamento.

## Navegação

Antes, abrir `shop` ou `research` da barra superior e apertar BACK levava sempre a `pause`, mesmo quando a navegação vinha do aquário ou da seleção. `Retro:openUtility()` salva a tela original ao abrir um utilitário e `Retro:leaveUtility()` retorna a essa tela. Alternar diretamente entre loja/pesquisa não cria uma sequência circular. Abrir diretamente uma dessas telas em teste ainda mantém o retorno padrão ao menu de pausa. O retorno pelo teclado e pelas softkeys é idêntico.

## Limite de fidelidade

Os ícones são extraídos dos recursos originais, mas a geometria precisa dos menus de ação e tratamento ainda não foi comparada a capturas do MIDlet executando tais páginas. Trata-se de melhoria baseada nos recursos disponíveis, não declaração de port 1:1 final. `core/game.lua`, as probabilidades de pesquisa e o formato do save não mudaram.
