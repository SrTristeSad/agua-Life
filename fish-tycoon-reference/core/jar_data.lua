-- Referencia estaticamente recuperada do n.class (J2ME v1.0.1).
-- A indexacao neste modulo usa 1..21 (indices Java 0..20).
-- b[i][j] = h[i] + g[j], exceto 13 substituicoes.
local M={}
M.bodyValues={2,10,5,10,2,14,5,25,8,10,15,10,2,18,15,10,9,10,9,20,2}
M.finValues={2,10,4,10,2,10,6,10,6,20,4,24,2,10,4,10,6,10,3,10,2}
M.overrides={
 [2]={[3]=30},
 [3]={[7]=33},
 [6]={[9]=70},
 [7]={[15]=33},
 [8]={[8]=190},
 [9]={[9]=20},
 [11]={[10]=70,[11]=33},
 [12]={[12]=70},
 [14]={[7]=95},
 [15]={[15]=55},
 [18]={[10]=45},
 [21]={[17]=48},
}
function M.basePrice(body,fin)
 local a=M.bodyValues[body];local b=M.finValues[fin];if not a or not b then return nil end
 local row=M.overrides[body]; return (row and row[fin]) or (a+b) end
-- m.a(1)=forma e m.a(2)=barbatana; n.b confere g[2] antes de g[1].
M.magic={
 {body=21, fin=17, index=0},
 {body=15, fin=15, index=1},
 {body=12, fin=12, index=2},
 {body=11, fin=10, index=3},
 {body=6, fin=9, index=4},
 {body=14, fin=7, index=5},
 {body=8, fin=8, index=6},
}
return M
