# Evidencias da integracao JAR

Arquivo examinado: `Fish_Tycoon_240x320-111845-mobiles24.jar`, manifest `MIDlet-Version: 1.0.1`.

| Implementacao | Evidencia estatica | Exatidao |
| --- | --- | --- |
| Indices 0..20 de variacoes | `j.S[2]`, `j.R[2]`, `j.T`, `j.U` | Confirmado |
| Corpo adulto: 50 px, x=0/50, y na tabela | `o.a(Graphics,int,int,m)` usa `m.a()` (50), `m.m()` e `m.l()` | Confirmado |
| Barbatana adulta: 32 px, x=0/32, x relativo +9 | `o.a(Graphics,int,int,m)` | Confirmado |
| Fins indice Java 19 inexistente | `j.T[19]=0`, `j.U[19]=0`, salto explicito no renderer | Confirmado |
| Sete combinacoes especiais | `j.l`, `n.b(m)` compara `m.a(2)` e `m.a(1)` | Confirmado |
| Matriz de precos base | `n.a()`, vetores `g`, `h`, 13 excecoes | Confirmado |
| Regulacao de mercado | `n.a(int,int)` adicao de `[-b/5,b/5)` e persistencia da matriz de venda | Aplicada em `core/market.lua`; compradores aproximados |
| Heranca genetica e cruzamento | JAR `n.class`, `l.class` | Pendente de reproducao exata |
| Musica OGG | renderizacao da fonte MIDI e sintetizador diferente | Adaptacao |
| Tanques/ciclo de vida | Kotlin anterior mais valores pontuais JAR | Misto / prototipo |

Nao se afirma que as mecanicas que ainda usam o port Kotlin estejam comprovadas pelo original. O projeto completo inclui `core/jar_data.lua` e `core/atlas.lua` com os indices e valores utilizados.
