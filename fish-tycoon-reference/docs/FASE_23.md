# Fase 23 — tipografia fiel ao JAR

Origem: `1.dat` do Fish Tycoon J2ME 1.0.1, recuperado do pacote entregue pelo usuário.

O bytecode da classe `i` converte texto para letras maiúsculas, mapeia caracteres ASCII para códigos internos e usa os deslocamentos horizontais por glifo, sem divisão uniforme do atlas. O módulo `ui/bitmap_font.lua` reproduz esses limites e alinha texto a uma área de largura fixa. A terceira fonte possui duas bandas de cor; utilizamos a inferior para os rótulos brancos e coloridos.

`assets/local_font` contém PNGs+metadados privados gerados pelo script e não versionados. O código público usa a fonte reserva do LÖVE quando ausentes.

**Pendente:** confrontar todas as telas com capturas do J2ME; a fidelidade 1:1 dos menus ainda não foi comprovada.
