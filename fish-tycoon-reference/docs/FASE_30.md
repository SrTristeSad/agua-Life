# Fase 30 — seleção fiel à referência 240 × 320

A captura original enviada pelo usuário mostra a seleção de um peixe com **contorno amarelo na área x=63..119, y=34..71**, logo abaixo da tarja com FED/HEALTH, nome e idade. Nas versões anteriores, o contorno seguia a posição de nado do peixe, podendo aparecer em qualquer lugar, inclusive encoberto por outro exemplar.

## Correção visual

No `ui/retro.lua`, somente enquanto `screen == "detail"`, o exemplar selecionado passa a ser desenhado no ponto lógico **(91,53)**, dentro de uma moldura de 56 × 37 pixels. Ele é o último renderizado do tanque, preservando corpo e contorno visíveis. Se outro peixe cruzaria o retângulo de destaque, só sua posição de desenho é deslocada para a borda mais próxima, mantendo os valores de `Swim.position` e o índice intactos. Ao voltar ao tanque, o peixe retoma sua animação normal.

Nenhuma propriedade física do peixe é alterada. Os sprites e as fontes comerciais seguem opcionais no repositório público; o pacote local preserva os recursos extraídos para estudo.

## Verificação

`tests/v30_selection.lua` verifica a geometria da seleção e a ordem de desenho para adulto e jovem, a navegação entre peixes e a versão do salvamento. O smoke nativo também deve capturar a tela de outro peixe. A reconstrução de todos os menus e a validação Android continuam pendentes.
