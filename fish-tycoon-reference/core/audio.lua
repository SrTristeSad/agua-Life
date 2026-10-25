local Audio={}; Audio.__index=Audio
function Audio.new() return setmetatable({tracks={},current=nil,enabled=true},Audio) end
function Audio:init()
 if not (love and love.audio and love.audio.newSource) then return end
 for _,name in ipairs({'menu','sale','tankTune1','tankTune2','tankTune3'}) do
  local ok,track=pcall(love.audio.newSource,'assets/audio/'..name..'.ogg','stream')
  if ok then track:setLooping(true);track:setVolume(name=='sale' and .19 or .25);self.tracks[name]=track end
 end
end
function Audio:pause()
 if self.current and self.tracks[self.current] then self.tracks[self.current]:stop() end
 self.current=nil
end
function Audio:toggle()
 self.enabled=not self.enabled
 if not self.enabled and self.current and self.tracks[self.current] then self.tracks[self.current]:stop();self.current=nil end
 return self.enabled
end
function Audio:update(page,room)
 if not self.enabled then return end
 local want
 if page~='tank' then want='menu'
 elseif room=='sale' then want='sale'
 elseif room=='second' then want='tankTune2'
 elseif room=='isolation' then want='tankTune3'
 else want='tankTune1' end
 if want==self.current then return end
 if self.current and self.tracks[self.current] then self.tracks[self.current]:stop() end
 self.current=want
 if self.tracks[want] then self.tracks[want]:play() end
end
return Audio
