-- JSON puro, sem execucao arbitraria de codigo durante o carregamento.
local json={}
-- Preserve container types from serialized input. An empty JSON object {}
-- must never be interchangeable with an empty JSON array [], especially
-- for tanks, purchased eggs, event queues and market history.
local arrayMeta={__json_kind='array'}
local objectMeta={__json_kind='object'}
function json.kind(value)
 local meta=type(value)=='table' and getmetatable(value)
 return type(meta)=='table' and meta.__json_kind or nil
end
local function escape(s)
  return '"' .. s:gsub('[%z\1-\31\\"]',function(c)
    local map={['\\']='\\\\',['"']='\\"',['\b']='\\b',['\f']='\\f',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
    return map[c] or string.format('\\u%04x',c:byte())
  end) .. '"'
end
local function array(t)
  if json.kind(t)=='object' then return false end
  local max, n=0,0
  for k in pairs(t) do
    if type(k)~='number' or k<1 or k%1~=0 then return false end
    if k>max then max=k end
    n=n+1
  end
  return max==n
end
local function encode(v,depth)
  depth=depth or 0
  assert(depth<60,'JSON profundo demais')
  local t=type(v)
  if t=='nil' then return 'null' end
  if t=='boolean' then return v and 'true' or 'false' end
  if t=='number' then
    assert(v==v and v~=math.huge and v~=-math.huge,'Numero invalido')
    return string.format('%.17g',v)
  end
  if t=='string' then return escape(v) end
  if t~='table' then error('Tipo nao serializavel: '..t) end
  local parts={}
  if array(v) then
    for i=1,#v do parts[#parts+1]=encode(v[i],depth+1) end
    return '['..table.concat(parts,',')..']'
  end
  for k,val in pairs(v) do
    assert(type(k)=='string','JSON: chaves precisam ser strings')
    parts[#parts+1]=escape(k)..':'..encode(val,depth+1)
  end
  table.sort(parts)
  return '{'..table.concat(parts,',')..'}'
end
json.encode=encode
function json.decode(str)
  assert(type(str)=='string','JSON esperado')
  local pos,n=1,#str
  local function fail() error('JSON invalido na posicao '..pos,0) end
  local function white() while pos<=n and str:sub(pos,pos):match('%s') do pos=pos+1 end end
  local value
  local function stringval()
    if str:sub(pos,pos)~='"' then fail() end
    pos=pos+1
    local out={}
    while pos<=n do
      local c=str:sub(pos,pos)
      if c=='"' then pos=pos+1;return table.concat(out) end
      if c=='\\' then
        pos=pos+1;c=str:sub(pos,pos)
        local map={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
        if map[c] then out[#out+1]=map[c];pos=pos+1
        elseif c=='u' then
          local h=str:sub(pos+1,pos+4)
          if not h:match('^%x%x%x%x$') then fail() end
          local cp=tonumber(h,16)
          if cp<128 then out[#out+1]=string.char(cp)
          elseif cp<2048 then out[#out+1]=string.char(192+math.floor(cp/64),128+cp%64)
          else out[#out+1]=string.char(224+math.floor(cp/4096),128+math.floor(cp/64)%64,128+cp%64) end
          pos=pos+5
        else fail() end
      else
        if c:byte()<32 then fail() end
        out[#out+1]=c;pos=pos+1
      end
    end
    fail()
  end
  value=function(depth)
    if depth>60 then fail() end
    white();local c=str:sub(pos,pos)
    if c=='"' then return stringval() end
    if c=='[' then
      pos=pos+1;white();local t=setmetatable({},arrayMeta)
      if str:sub(pos,pos)==']' then pos=pos+1;return t end
      while true do
        -- Nao comprimir silenciosamente [peixe,null,peixe]:
        -- no save, isso apaga um indice e pode eliminar animais sem erro.
        -- Objetos continuam permitindo null como chave ausente.
        local item=value(depth+1)
        if item==nil then fail() end
        t[#t+1]=item;white();c=str:sub(pos,pos);pos=pos+1
        if c==']' then return t end
        if c~=',' then fail() end
      end
    end
    if c=='{' then
      pos=pos+1;white();local t,seen=setmetatable({},objectMeta),{}
      if str:sub(pos,pos)=='}' then pos=pos+1;return t end
      while true do
        white();local k=stringval();white()
        -- Duas chaves iguais no mesmo objeto sobrescreviam uma a outra
        -- silenciosamente (inclusive tanks.main, stats e cash).
        if seen[k] then fail() end
        seen[k]=true
        if str:sub(pos,pos)~=':' then fail() end
        pos=pos+1;t[k]=value(depth+1);white();c=str:sub(pos,pos);pos=pos+1
        if c=='}' then return t end
        if c~=',' then fail() end
      end
    end
    local tail=str:sub(pos)
    if tail:sub(1,4)=='true' then pos=pos+4;return true end
    if tail:sub(1,5)=='false' then pos=pos+5;return false end
    if tail:sub(1,4)=='null' then pos=pos+4;return nil end
    local token=tail:match('^-?%d+%.?%d*[eE]?[-+]?%d*')
    if token and token~='' then
      local num=tonumber(token)
      if num then pos=pos+#token;return num end
    end
    fail()
  end
  local result=value(0);white();if pos<=n then fail() end
  return result
end
return json
