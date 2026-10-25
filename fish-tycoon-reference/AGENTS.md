# Instruções de desenvolvimento — Fish Tycoon Lua

## Fonte principal

O repositório `SrTristeSad/Fish-Tycoon-Lua`, branch `main`, é a referência canônica do projeto. A base atual é a versão **v21**, em Lua + LÖVE 2D.

## Regra obrigatória de versionamento

**Toda alteração futura neste projeto deve ser registrada no GitHub em commit Git.** Não entregar apenas ZIPs ou arquivos locais sem também atualizar o repositório. Antes de desenvolver, consultar o código remoto atual para evitar regressões ou sobrescrever alterações de outro trabalho.

- Continuar a base existente; não reconstruir o projeto do zero.
- Preservar salvamentos, código, gráficos e áudio existentes, exceto quando a mudança tiver sido solicitada.
- Realizar mudanças pequenas e documentadas com mensagens de commit descritivas.
- Rodar testes Lua pertinentes (`tests/`) e atualizar/adicionar testes para correções.
- Confirmar o SHA do commit publicado e informar seu link ao usuário.
- Não substituir fórmulas aproximadas por alegações de fidelidade ao JAR sem evidência.

## Recursos e direitos

A pasta `assets/original` e os arquivos em `assets/audio` contêm recursos derivados do jogo comercial, destinados a estudo. Consulte `RECURSOS_E_DIREITOS.md` antes de qualquer redistribuição ou lançamento público.

## Execução

Leia `README.md`. Para os testes, use `texlua tests/run.lua` ou execute as suítes sob `tests/`; a interface usa LÖVE 2D 11.4.
