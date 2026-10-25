-- Agua Life: 100% original / dados da arte procedural
local M={}
local raw={
{"Luar",.98,.74,.90,.98,0,.00},{"Vagalume",.91,.79,.84,1.10,.08,.08},
{"Cometa",1.21,.55,1.24,.82,-.08,-.08},{"Pingo",.73,.98,.72,1.08,.10,.13},
{"Sereia",1.07,.76,1.11,.90,-.12,.02},{"Safira",1.12,.71,.90,1.23,-.08,-.06},
{"Douradinho",.90,.88,.77,1.24,.08,.04},{"Vento",1.35,.48,1.30,.72,-.15,-.10},
{"Orquidea",.95,1.08,1.17,1.04,.16,.08},{"Raio",1.26,.59,.93,.97,-.04,-.12},
{"Lagrima",.78,1.16,.77,1.34,.10,.08},{"Nuvem",1.00,.97,.98,1.16,.04,.07},
{"Nadador",1.14,.72,1.21,.83,-.04,-.04},{"Ametista",.94,.89,.83,1.22,.04,-.03},
{"Esmeralda",1.08,.81,1.15,1.05,-.02,.04},{"Faisca",1.31,.56,1.00,.78,-.12,-.10},
{"Jade",1.05,.90,1.07,1.20,.03,.04},{"Perola",.85,1.07,.70,1.15,.14,.13},
{"Gota",1.16,.79,1.08,.98,-.08,-.04},{"Caramelo",.92,.92,1.19,.92,.03,.08},
{"Aurora",1.03,.84,.87,1.10,.02,.01}}
M.bodies={}
for i,b in ipairs(raw) do
 M.bodies[i]={id=i,name=b[1],length=b[2],height=b[3],upper=b[4],lower=b[5],head=b[6],curvature=b[7]}
end
local tails={
{"Leque","fan",1,1},{"Lua","round",.91,.92},{"Andorinha","fork",1.09,1.15},
{"Veu","veil",1.25,1.42},{"Flecha","spear",1.18,.54},{"Cristal","diamond",.98,1.16},
{"Duas Luas","double",1.20,1.12},{"Cintilante","fan",1.12,1.17},
{"Rubi","round",.95,.83},{"Estrela","fork",1.30,1.18},
{"Flamula","veil",1.46,1.11},{"Agulha","spear",1.32,.46},
{"Coral","fan",.95,1.34},{"Duna","round",1.14,.87},{"Arco","fork",.87,1.04},
{"Seda","veil",1.10,1.63},{"Solar","diamond",1.24,1.26},
{"Lotus","double",1.06,1.43},{"Valsa","fan",1.35,.96},
{"Brisa","spear",.83,.74},{"Realeza","veil",1.43,1.73}}
M.fins={}
for i,f in ipairs(tails) do M.fins[i]={id=i,name=f[1],kind=f[2],length=f[3],spread=f[4]} end
M.palettes={
{name="Aurora",base="#4ABBB0",back="#155F84",belly="#C9FFF0",accent="#F9C971",fin="#197CA0",light="#F5FFF6"},
{name="Coral",base="#F67D60",back="#9D2C61",belly="#FFE2A4",accent="#FAD66F",fin="#B94184",light="#FFF0C9"},
{name="Celeste",base="#69B9EC",back="#284FAD",belly="#E2FFFF",accent="#E9A953",fin="#3655BE",light="#FFFFFF"},
{name="Jade",base="#68C88B",back="#176E63",belly="#ECFFD0",accent="#F0DE77",fin="#3D8F6D",light="#FFFFFF"},
{name="Lavanda",base="#B58FD9",back="#583E91",belly="#FFE9FF",accent="#FBBFA2",fin="#7759AD",light="#FFFFFF"},
{name="Sol",base="#FFB749",back="#D86245",belly="#FFF2BA",accent="#FFEE80",fin="#EF744B",light="#FFFCF0"},
{name="Noite",base="#436E82",back="#24304D",belly="#A4E1D8",accent="#EBC87F",fin="#344766",light="#EDFAFC"},
{name="Rosa",base="#ECA0C5",back="#9F528F",belly="#FFEEE8",accent="#F5D682",fin="#B85B9F",light="#FFFFFF"},
{name="Oceanico",base="#2EA7C3",back="#124A86",belly="#B6F7EB",accent="#8DD9D0",fin="#176DA4",light="#E7FFFC"},
{name="Citrino",base="#D7D75C",back="#71834A",belly="#FFF4B1",accent="#F08D5D",fin="#A2A55F",light="#FFFFEB"},
{name="Cereja",base="#D95979",back="#813965",belly="#FFBDB6",accent="#F1AB6C",fin="#AA426F",light="#FFF1E8"},
{name="Gelo",base="#B0DCE7",back="#5D879F",belly="#FEFFEA",accent="#CDE7EF",fin="#7DB0BF",light="#FFFFFF"}
}
function M.wrap(n,count)return ((math.floor(n)-1)%count)+1 end
function M.get(body,fin,palette,pattern)
 body=M.wrap(body or 1,#M.bodies)
 fin=M.wrap(fin or 1,#M.fins)
 palette=M.wrap(palette or 1,#M.palettes)
 return {body=body,fin=fin,palette=palette,pattern=((math.floor(pattern or body)-1)%6)+1}
end
function M.valid(f)
 return type(f)=="table" and type(f.body)=="number" and type(f.fin)=="number" and
 f.body>=1 and f.body<=#M.bodies and f.fin>=1 and f.fin<=#M.fins and
 type(f.palette)=="number" and f.palette>=1 and f.palette<=#M.palettes
end
return M
