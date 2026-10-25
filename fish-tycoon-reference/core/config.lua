-- Port independente da estrutura FishTycoonAndroid. Valores PROVISORIOS
-- herdados de Config.kt, nao validados contra o JAR J2ME original.
return {
  -- JAR n.b(m,boolean): 60 * {5,10,15} segundos por unidade de idade.
  -- Intervalo intermediario = 10 min. A opção pode ser alterada no jogo.
  YEAR = 10 * 60,
  GROWTH_OPTIONS = {5,10,15},
  EGG = 30 * 60,
  MAX_OFFLINE = 24 * 60 * 60,
  FED_DECAY = 12,
  HUNGRY_DAMAGE = 6,
  STARVE_DAMAGE = 15,
  HEAL = 2,
  SICK_CHANCE = .05,
  SICK_DAMAGE = 4,
  -- Vendas/filhotes agora seguem Mercado/JAR; constantes antigas desativadas.
  -- A classe o.class aloca 18 slots por tanque J2ME, inclusive vendas.
  -- O isolamento continua com dois slots por ser uma escolha de interface Lua.
  CAPACITY = {main = 18, second = 18, isolation = 2, sale = 18},
  RESEARCH_MAX = 3,
  RESEARCH_COSTS = {environment = {120, 260, 480}, food = {90, 200, 390}, advertising = {100, 230, 450}},
  RESEARCH_SECONDS = {4*60, 8*60, 14*60},
}
