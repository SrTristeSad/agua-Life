# Peixe Azul-Rubi: rig modular original

## Objetivo

Primeiro modelo de peixe do `agua-Life` com peças **separadas fisicamente** e animáveis em tempo real, sem copiar ou melhorar sprites comerciais do Fish Tycoon.

![Amostra montada](../assets/fish/azul_rubi/preview.png)

## Fonte, formatos e artefatos

A fonte procedural é `scripts/generate_azul_rubi.py`. Ela escreve, em `assets/fish/azul_rubi/`:

- 12 arquivos `*.svg` originais e 12 `*.png` com alfa RGBA.
- `rig.json`: dimensão da prancheta e articulações para importar no jogo.
- `preview.png` e `swim.gif`: exemplos com as peças montadas.

**Prancheta de origem:** 320×180. **Exportação:** 640×360 (2×). A área transparente **não é cortada**, pois manter todos os elementos na mesma prancheta garante que girar um componente sobre o seu pivô não altere o alinhamento.

### Articulação por peça

| Arquivo | Pivô em px, coordenadas da prancheta 320×180 | Como anima |
|---|---|---|
| `body.png` | Centro global do peixe | Rotação de 0,013 rad e oscilação vertical |
| `tail.png` | (110, 94) | ±0,22 rad, nado lateral |
| `dorsal.png` | (187, 64) | ±0,068 rad |
| `pelvic.png` | (176, 121) | ±0,105 rad |
| `pectoral.png` | (245, 104) | ±0,28 rad |
| `eye.png` | (273, 85) | Pisca por compressão vertical temporária |
| `pattern_1.png` a `pattern_6.png` | Fixo sobre o corpo | Troca conforme DNA |

**Ordem de desenho:** cauda → dorsal → ventral → corpo → estampa → peitoral → olho.

O `art/rigged_fish.lua` carrega as imagens sob demanda, calcula a pose a cada `draw`, gira peças em seus pontos e recompõe a figura. Imagens são cacheadas. `Rig.pose(time, isSick)` é determinística e independente de LÖVE, permitindo testes de regressão.

A interface **Ateliê** (`3`) mostra cada parte isolada usando o **mesmo PNG** empregado na composição — não é uma montagem de demonstração artificial. **J** revela os pivôs no peixe montado.

## DNA e comportamento

O primeiro molde modular é utilizado quando `body=1` e `fin=1`. Os genes `palette` (1–12) e `pattern` (1–6) afetam a aparência. Outras combinações de corpo/cauda permanecem no gerador `art/fish.lua` até receberem seu próprio conjunto de peças.

A seleção de paleta aplica um deslocamento de matiz no shader, sem alterar os PNGs originais. O DNA seleciona a estampa desenhada sobre o corpo. No estado de doença, a cauda e demais nadadeiras oscilam mais lentamente e com amplitude menor.

**Neste estágio** não há morfagem entre dois corpos, transição de malha individual por genética, nem variantes de olho ou cabeça. O genótipo herdável já existe em `genetics/dna.lua`; a integração com essas próximas partes acontecerá quando forem desenhadas.

## Testes

`tests/rigged_fish.lua` testa 72 combinações, pivôs, herança e curvas de animação. O GitHub Actions valida transparência, PNGs, metadados e testa uma composição em execução real do LÖVE num servidor X virtual (`AGUA_RIG_SMOKE=1`).

## Reproduzir sprites

```bash
python -m pip install pillow cairosvg
python scripts/generate_azul_rubi.py
```

O executável final do jogo só precisa do LÖVE e das imagens produzidas, não de Python.
