# agua-Life — roteiro testável da base jogável 0.1

## Caminho de uma partida

1. Abrir o jogo e escolher **Nova partida**. Começa com $280, 12 rações, 2 remédios e 4 peixes.
2. Selecionar o primeiro adulto e clicar **Cruzar**, depois clicar no segundo adulto. A incubação custa $12 e leva 4 ciclos, cada um de 6 segundos.
3. Observar o novo filhote e abrir o **Exame de DNA (F8)**. Ele carrega dois alelos por característica: a aparência expressa a média inteira dos alelos.
4. Esperar o filhote envelhecer até 20 ciclos; alimentar quando necessário.
5. Vender outro adulto, ganhando moedas. Comprar ovos, ração e remédios na **Loja**.
6. Desbloquear o segundo aquário e transferir um peixe, mantendo a capacidade máxima de 14 exemplares por tanque.
7. Abrir **Coleção (5)** para conferir a matriz 21×21 e as combinações descobertas.
8. Abrir **Ateliê (6)** e alternar as juntas usando J. O Azul-Rubi tem peças de imagem reais.
9. Salvar e fechar. Reabrir e clicar em **Continuar** para recuperar a partida.
10. Se algum peixe morrer, usar **F9** para consultar o relatório de necropsia.

## Condições de derrota e recuperação

O jogo não impõe game over definitivo: se todos os peixes morrerem, o jogador pode comprar ovos quando tiver fundos. O jogador deve manter dinheiro e estoque suficientes para sustentar a criação; nesta versão ainda não há mecanismo de empréstimo ou resgate de partida economicamente inviável.

## Regras atuais

- Condição para cruzar: dois peixes diferentes, adultos, saudáveis e no mesmo tanque; máximo de três incubações simultâneas.
- Tratamento para doença ativa consome uma dose e tem 60% de chance de sucesso.
- Ração aumenta alimentação em 35 pontos, até o limite 100.
- Ciclo de saúde: 6 segundos, em média um ponto de alimento por ciclo; doenças e fome reduzem saúde.
- Sem monetização real ou microtransações.
- Duas salas físicas; o catálogo 21×21 é uma interface de descoberta, não um tanque.
- Jogo independente sem redistribuição das artes comerciais do Fish Tycoon.

## Limites e prioridades futuras

O motor original 1:1 permanece em fish-tycoon-reference e não foi totalmente fundido. Para um lançamento comercial, aprofundar qualidade visual de todos os 21 corpos, completar animações por anatomia, equilibrar doenças/reprodução e testar extensivamente em Windows/Android antes de considerar a versão pronta.
