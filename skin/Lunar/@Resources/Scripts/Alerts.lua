-- Pure policy: callers persist a key BEFORE displaying its alert.
local N={}
function N.due(events,now,settings,seen)
    if not settings.enabled then return {} end
    local out={}
    for _,e in ipairs(events) do
        if e.quarter==2 or settings.allPhases then
            local reminders={}
            if settings.advance then reminders[#reminders+1]=settings.hours end
            if settings.atEvent then reminders[#reminders+1]=0 end
            for _,hours in ipairs(reminders) do
                local key=e.id..':'..hours
                local trigger=e.time-hours*3600
                if not seen[key] and now>=trigger and now-trigger<=settings.grace*3600
                    and (hours==0 or now<e.time) then
                    out[#out+1]={key=key,event=e,hours=hours}
                end
            end
        end
    end
    return out
end
function N.load(path)
    local seen={}
    local f=io.open(path,'r')
    if f then
        for line in f:lines() do
            if line:match('^%-?%d+:[0-3]:%d+$') then seen[line]=true end
        end
        f:close()
    end
    return seen
end
function N.commit(path,key,seen)
    if seen[key] then return false end
    local f=io.open(path,'a')
    if not f then return false end
    local ok=f:write(key..'\n')
    local closed=f:close()
    if not ok or not closed then return false end
    seen[key]=true
    return true
end
return N
