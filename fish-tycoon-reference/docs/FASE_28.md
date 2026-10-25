# Fase 28 — ações, tratamento e transferência (interface 240×320)

Correções dirigidas à usabilidade da reconstrução J2ME. O motor e salvamentos existentes foram preservados integralmente.

## Ações do peixe

O painel anterior tinha seis botões grandes numa grade genérica. Foi substituído por seis linhas compactas com informações da espécie, idade, saúde e preço. Alimentar é indisponível se faltar comida ou o peixe estiver saciado; controles de preço e venda direta são exibidos, porém inativos, fora do tanque de vendas ou para peixes jovens. O tratamento e a transferência levam aos submenus correspondentes.

## Transferir

Exibir quatro destinos e a ocupação real de cada sala evita perder comandos em tentativas impossíveis. Mesma sala, segundo aquário fechado, capacidade máxima, venda de filhotes e gestação em isolamento são bloqueados. A validação real continua em `Game:move()`.

## Tratamento

Exibe a doença e estoque. Cura de Ick/Fungos só pode ser selecionada para doença correspondente; o botão de hormônio não permite animais com idade maior que 40; estoque zero bloqueia a ação. `Game:medicine()` preserva a lógica de cura e consumo.

## Testes e limite de fidelidade

`tests/v28_actions.lua` testa disponibilidade, quantidade, transferência, retorno e preservação de dados. `core/retro_smoke.lua` e `scripts/validate_retro_screenshots.py` testam 18 telas com o LÖVE real em GitHub Actions. As novas telas compactas **não são uma alegação de reprodução 1:1 do visual desconhecido do JAR**: é necessária referência visual para tratar espaçamento e ícones como canônicos.
