# Direcao de arte — agua-Life

Arte original de peixes de fantasia para um jogo 2D de aquario.

## Principios

1. Silhueta legivel em tamanho pequeno e harmonica em zoom.
2. Gradientes suaves de dorso para barriga, construidos por vertices.
3. Barbatanas como superficies proprias, com nervuras e movimento.
4. Diferenciacao real de anatomia (nao somente trocar cores).
5. Ausencia de sprites comerciais e atlas importados.

## Sistema

21 corpos x 21 caudas = **441 combinacoes anatomicas**.
Cada peixe recebe tambem 12 possibilidades de paleta e 6 ornamentos.
O codigo manipula a morfologia por parametros independentes e gera vertices
para o rasterizador grafico do LÖVE. Nao carrega nenhuma textura.

## Estado

Este repositorio contem um laboratorio visual executavel, nao as mecanicas
completas de simulacao. Proxima etapa: refinar anatomia apos teste visual no
Windows, modelar hereditariedade e criar um sistema de peixes e criacao.
