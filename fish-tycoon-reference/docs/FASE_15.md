# Fase 15 — margens visuais e testes de toque

A fase 15 continua a v14. As imagens comerciais do JAR permanecem inalteradas; nenhum arquivo de áudio ou PNG foi adicionado ou removido.

## Ajuste visual

`ui/swim.lua` usa uma grade de 4 colunas e até 5 linhas com limites de deslocamento `x=70..351` e `y=233..453`, calculados para o painel de água de `23..397` e `170..501`. Assim a área de corpo e o indicador de seleção de peixes adultos ficam dentro do painel mesmo nas extremidades, evitando sobreposição com o cabeçalho e o painel de ações. O isolador mantém as posições anteriores; a simulação e o RNG não mudaram.

## Verificações de interface

`tests/v15_controls.lua` lê as dimensões reais dos sprites e simula a API de desenho do LÖVE, verificando:

- posições dos 18 peixes e dos dois peixes de isolamento em muitas amostras de tempo;
- navegação das quatro abas em 360×620, 420×800, 468×858, 1000×600 e 1280×960;
- toque nas áreas pretas de letterbox sem acionar controles;
- seleção do peixe e navegação de tanques em uma resolução pequena;
- janelas modais bloqueando toques e atalhos no conteúdo atrás delas;
- limites de todos os botões da tela inicial.

## Limite de validação

Os testes usam `texlua` e mocks gráficos; **não representam uma janela real do LÖVE nem captura do compositor**. Não foi possível instalar/executar o LÖVE nativo neste ambiente. Testes visuais reais e Android permanecem pendentes. Também não há comprovação adicional das probabilidades genéticas ou das regras de pesquisa do MIDlet nesta fase.
