# Fase 6 — Saúde, alimentação e ambiente

## Continuidade
Esta versão parte diretamente do código v5 e preserva todas as outras funcionalidades, os recursos de imagem/áudio e o diretório de salvamento `mar_de_isola_lua`.

## Regras recuperadas do JAR 1.0.1

Foi examinado o bytecode de `n.class` (`fish_jar_analysis/disassembly/n.txt`) com índices Java 0–20 convertidos para os índices Lua 1–21.

- `n.a(m,boolean)`, ramo `b.g(17)`: chance de perder uma unidade da reserva alimentar a cada atualização: **100%, 61% ou 31%**, conforme a opção 1, 2 ou 3. Módulo: `core/care.lua`, `foodDrainChance`.
- `n.c(m)`, ramo `b.g(26)`: alteração de saúde em função da paridade dos índices de corpo e barbatana. Valores por níveis 1, 2, 3: índice ímpar em qualquer parte `[-19,-6,0]`; `(indice-2)%4==0` `[-1,+1,+3]`; índice múltiplo de 4 `[+1,+3,+5]`; outras formas `[0,0,0]`. Os grupos seguem a ordem de decisão do Java. Módulo: `environmentDelta`.
- `n.a(m,int)`: limiares de risco básico para adoecer em 10.000 sorteios, pelo índice da forma e a opção nutricional: múltiplos de 4 `[10,5,1]`, outros pares com resto 2 `[20,10,3]`, ímpares `[30,20,5]`. Módulo: `originalDiseaseThreshold`.

**Limitações importantes:** A equivalência entre opções `b.g(17)` e a pesquisa Lua de alimentação, assim como entre `b.g(26)` e pesquisa ambiental, é uma hipótese de integração. O MIDlet não foi executado em emulador para comprovar a interface de configuração. O jogo Lua mapeia o nível 0 à opção 1, nível 1 à opção 2 e nível 2 à opção 3.

## Adaptações novas, NÃO recuperadas do Java

- O nível 3 de alimentação oferece 20% de perda de reserva e o nível 3 ambiental acrescenta +2 de proteção, para evitar que a terceira pesquisa (que existia no protótipo Lua) seja inútil.
- Planta reduz chance de fome em 25%; aquecedor, aerador e caracol acrescentam proteção; densidade elevada triplica chance de doença; fome extrema aumenta suscetibilidade. São decisões de gameplay e ficam concentradas em `Care.step` para facilitar substituição quando a lógica restante do JAR for recuperada.
- A fome abaixo de 20 unidades penaliza a saúde para sinalizar necessidade de alimentação, e o estado de doença penaliza por ciclo. Efeitos mágicos preexistentes foram mantidos.
- Probabilidade de doença baixa: observar que o Java usa amostras de 10.000, não as taxas de 5% que o protótipo tinha.

## Mudanças visíveis

- Pequeno painel nos tanques: saúde média, alimento médio e total de peixes doentes.
- Informações do peixe: resistência base ambiental por sua combinação de corpo e barbatana.
- Pesquisa mostra o efeito esperado do nível atual, em vez de uma descrição genérica.
- Estatística de infecções no salvamento. Evolução de schema 5 para 6, sem alterar os dados de gestação, cotação ou genética.

## Verificação

Na raiz do projeto, use:

```sh
texlua tests/run.lua
texlua tests/v4_regression.lua
texlua tests/v5_regression.lua
texlua tests/v6_regression.lua
texlua tests/view_smoke.lua
texlua tests/v5_ui_smoke.lua
texlua tests/v6_ui_smoke.lua
texlua tests/lifecycle_smoke.lua
texlua tests/jar_resources_smoke.lua
```

Todos são testes de código e simulações da UI. A execução em janela do LÖVE e em Android **não foi validada** nesta etapa.
